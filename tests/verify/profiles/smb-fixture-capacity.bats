#!/usr/bin/env bats

# bats file_tags=nas,smb-fixtures,capacity
# shellcheck source=tests/verify/lib/smb-fixture-client.sh
# shellcheck disable=SC1091
source "$BATS_TEST_DIRNAME/../lib/smb-fixture-client.sh"
# shellcheck source=tests/verify/lib/suite-lock.sh
# shellcheck disable=SC1091
source "$BATS_TEST_DIRNAME/../lib/suite-lock.sh"

setup_file() {
  verification_acquire_suite_lock 900
}

teardown_file() {
  verification_release_suite_lock
}

setup() {
  SERVER=${HOMELAB_NAS_ADDRESS:-10.10.10.11}
  AUTH_FILE=${HOMELAB_VERIFICATION_AUTH_FILE:-"$HOME/.config/homelab/verification-smb.auth"}
  VERIFICATION_RUN_ID=$(verification_new_run_id)
  export VERIFICATION_RUN_ID
  MAX_BYTES_FILES=70
  MAX_INODE_FILES=4500
  DEADLINE_SECONDS=300
}

ordinary_share_is_listable() {
  timeout --foreground 30 ssh -o BatchMode=yes \
    -i "$HOME/.ssh/id_ed25519" "operator@$SERVER" \
    'smbclient -N //127.0.0.1/mediaBin -c ls >/dev/null'
}

capacity_exercise() {
  local mode=$1 mountpoint namespace prefix limit block_size minimum_success start created=0 cleanup_limit=0 rejected=false index path diagnostic
  local cleanup_error='' allocation_error=''
  mountpoint=$(mktemp -d)
  if ! mount_authenticated "$AUTH_FILE" "$SERVER" 'homelab-verification$' "$mountpoint"; then
    rmdir "$mountpoint"
    printf 'capacity profile could not mount verification endpoint\n' >&2
    return 1
  fi
  namespace="$mountpoint/$VERIFICATION_RUN_ID"
  verification_create_namespace "$mountpoint" "$VERIFICATION_RUN_ID"

  case $mode in
    bytes)
      prefix=byte
      limit=$MAX_BYTES_FILES
      block_size=1048576
      minimum_success=8
      ;;
    inodes)
      prefix=inode
      limit=$MAX_INODE_FILES
      block_size=0
      minimum_success=100
      ;;
    *) return 2 ;;
  esac

  diagnostic=$(mktemp)
  start=$SECONDS
  for (( index = 1; index <= limit; index++ )); do
    if (( SECONDS - start >= DEADLINE_SECONDS )); then
      printf '%s capacity exercise exceeded %ss for run %s\n' \
        "$mode" "$DEADLINE_SECONDS" "$VERIFICATION_RUN_ID" >&2
      break
    fi
    path="$namespace/$prefix-$index"
    if [[ $mode == bytes ]]; then
      if timeout --foreground 15 /bin/dd if=/dev/zero of="$path" bs=$block_size count=1 2>"$diagnostic"; then
        created=$index
      else
        rejected=true
        break
      fi
    elif timeout --foreground 15 /usr/bin/touch "$path" 2>"$diagnostic"; then
      created=$index
    else
      rejected=true
      break
    fi
  done

  if $rejected; then
    if (( created < minimum_success )); then
      allocation_error="$mode capacity rejected before the minimum successful allocation count ($created < $minimum_success)"
    elif ! grep -Eiq 'no space left on device|disk quota exceeded|quota' "$diagnostic"; then
      allocation_error="$mode allocation failed without a capacity diagnostic: $(<"$diagnostic")"
    fi
  else
    allocation_error="$mode allocation did not fail within the client ceiling"
  fi
  [[ -z $allocation_error ]] || cleanup_error=$allocation_error
  ordinary_share_is_listable || cleanup_error="${cleanup_error:+$cleanup_error; }ordinary share unavailable"

  cleanup_limit=$created
  $rejected && cleanup_limit=$index
  for (( index = 1; index <= cleanup_limit; index++ )); do
    path="$namespace/$prefix-$index"
    [[ ! -e $path && ! -L $path ]] || /bin/rm -- "$path" || cleanup_error="${cleanup_error:+$cleanup_error; }file cleanup failed"
    path="$namespace/._$prefix-$index"
    [[ ! -e $path && ! -L $path ]] || /bin/rm -- "$path" || cleanup_error="${cleanup_error:+$cleanup_error; }sidecar cleanup failed"
  done
  verification_remove_namespace "$mountpoint" "$VERIFICATION_RUN_ID" || cleanup_error="${cleanup_error:+$cleanup_error; }residual run $VERIFICATION_RUN_ID"
  path="$mountpoint/._$VERIFICATION_RUN_ID"
  [[ ! -e $path && ! -L $path ]] || /bin/rm -- "$path" || cleanup_error="${cleanup_error:+$cleanup_error; }namespace sidecar remains"
  timeout --foreground 30 /sbin/umount "$mountpoint" || cleanup_error="${cleanup_error:+$cleanup_error; }verification unmount failed"
  rmdir "$mountpoint" 2>/dev/null || cleanup_error="${cleanup_error:+$cleanup_error; }mountpoint remains"
  rm -f "$diagnostic"

  [[ -z $cleanup_error ]] || {
    printf 'capacity exercise failed for %s after %d files; %s\n' \
      "$VERIFICATION_RUN_ID" "$created" "$cleanup_error" >&2
    return 1
  }
  printf '%s capacity rejected allocation after %d files; ordinary share remained listable; run %s cleaned\n' \
    "$mode" "$created" "$VERIFICATION_RUN_ID"
}

@test "verification byte capacity rejects further allocation without consuming ordinary storage" {
  run capacity_exercise bytes
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
  [[ $output == *"bytes capacity rejected allocation"* ]]
}

@test "verification inode capacity rejects further allocation without consuming ordinary storage" {
  run capacity_exercise inodes
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
  [[ $output == *"inodes capacity rejected allocation"* ]]
}
