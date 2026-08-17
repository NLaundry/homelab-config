#!/usr/bin/env bats

# bats file_tags=nas,samba

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  SERVER=${HOMELAB_NAS_ADDRESS:-"$(yq -r '.all.children.nas.hosts.nasty.ansible_host' "$ROOT/ansible/inventory.yml")"}
  EXPECTED_SHARES=(mediaBin smolBoy)
}

cleanup_guest_resources() {
  trap - EXIT INT TERM
  GUEST_CLEANUP_ERROR=''
  if [[ ${GUEST_NAMESPACE_CREATED:-false} == true ]]; then
    rm -f -- "$GUEST_FIXTURE" || GUEST_CLEANUP_ERROR='guest fixture cleanup failed'
    rmdir -- "$GUEST_MOUNTPOINT/$GUEST_NAMESPACE" ||
      GUEST_CLEANUP_ERROR="${GUEST_CLEANUP_ERROR:+$GUEST_CLEANUP_ERROR; }guest namespace cleanup failed"
  fi
  if [[ ${GUEST_MOUNT_ATTEMPTED:-false} == true ]]; then
    /sbin/umount "$GUEST_MOUNTPOINT" ||
      GUEST_CLEANUP_ERROR="${GUEST_CLEANUP_ERROR:+$GUEST_CLEANUP_ERROR; }guest unmount failed"
  fi
  if [[ -n ${GUEST_MOUNTPOINT:-} && -d $GUEST_MOUNTPOINT ]]; then
    rmdir "$GUEST_MOUNTPOINT" ||
      GUEST_CLEANUP_ERROR="${GUEST_CLEANUP_ERROR:+$GUEST_CLEANUP_ERROR; }local mountpoint cleanup failed"
  fi
  [[ -z $GUEST_CLEANUP_ERROR ]]
}

guest_share_round_trip() {
  local share=$1 expected observed original_error=''
  GUEST_MOUNTPOINT=$(mktemp -d)
  GUEST_NAMESPACE_CREATED=false
  GUEST_MOUNT_ATTEMPTED=false
  GUEST_FIXTURE=''
  trap cleanup_guest_resources EXIT
  trap 'cleanup_guest_resources; exit 130' INT
  trap 'cleanup_guest_resources; exit 143' TERM
  GUEST_NAMESPACE=".homelab-verify-$(date -u +%Y%m%dT%H%M%SZ)-$$-$RANDOM"
  GUEST_FIXTURE="$GUEST_MOUNTPOINT/$GUEST_NAMESPACE/round-trip.txt"
  expected="homelab guest SMB verification $GUEST_NAMESPACE"

  GUEST_MOUNT_ATTEMPTED=true
  if ! /sbin/mount_smbfs -N -o nobrowse,soft,nopassprompt -s \
    "//guest@$SERVER/$share" "$GUEST_MOUNTPOINT"; then
    cleanup_guest_resources || true
    printf 'guest mount failed for %s/%s\n' "$SERVER" "$share" >&2
    return 1
  fi

  ls -la "$GUEST_MOUNTPOINT" >/dev/null || original_error='guest directory listing failed'
  if [[ -z $original_error ]] && mkdir "$GUEST_MOUNTPOINT/$GUEST_NAMESPACE"; then
    GUEST_NAMESPACE_CREATED=true
  elif [[ -z $original_error ]]; then
    original_error='unique guest namespace creation failed'
  fi
  if [[ -z $original_error ]]; then
    printf '%s\n' "$expected" >"$GUEST_FIXTURE" || original_error='guest write failed'
  fi
  if [[ -z $original_error ]]; then
    observed=$(<"$GUEST_FIXTURE") || original_error='guest read failed'
    [[ $observed == "$expected" ]] || original_error='guest content mismatch'
  fi

  cleanup_guest_resources || true
  if [[ -n $original_error ]]; then
    printf '%s guest behavior failed: %s\n' "$share" "$original_error" >&2
    [[ -z $GUEST_CLEANUP_ERROR ]] || printf 'cleanup also failed: %s\n' "$GUEST_CLEANUP_ERROR" >&2
    return 1
  fi
  if [[ -n $GUEST_CLEANUP_ERROR ]]; then
    printf '%s guest behavior cleanup failed: %s\n' "$share" "$GUEST_CLEANUP_ERROR" >&2
    return 1
  fi
  printf '%s supports guest list, write, read, delete, and clean unmount\n' "$share"
}

@test "the NAS advertises every expected ordinary SMB share to guests" {
  local listing share
  run smbutil view -N -G "//$SERVER"
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
  listing=$output
  for share in "${EXPECTED_SHARES[@]}"; do
    [[ $listing =~ (^|[[:space:]])$share([[:space:]]|$) ]] || {
      printf 'expected guest share is absent: %s\n%s\n' "$share" "$listing" >&2
      return 1
    }
  done
}

@test "mediaBin behaves as a guest-readable and guest-writable share" {
  run guest_share_round_trip mediaBin
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
}

@test "smolBoy behaves as a guest-readable and guest-writable share" {
  run guest_share_round_trip smolBoy
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
}
