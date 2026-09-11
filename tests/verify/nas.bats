#!/usr/bin/env bats

# bats file_tags=nas,samba
# shellcheck source=tests/verify/lib/deployment-health.sh
source "$BATS_TEST_DIRNAME/lib/deployment-health.sh"
# shellcheck source=tests/verify/lib/nas-samba-safety.sh
source "$BATS_TEST_DIRNAME/lib/nas-samba-safety.sh"

setup_file() {
  require_smb_tools
}

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  NAS_ADDRESS=${HOMELAB_NAS_ADDRESS:-"$(yq -r '.all.children.nas.hosts.nasty.ansible_host' "$ROOT/ansible/inventory.yml")"}
  SSH_COMMAND=${HOMELAB_DEPLOYMENT_SSH_COMMAND:-ssh}
  SSH_IDENTITY=${HOMELAB_DEPLOYMENT_SSH_IDENTITY:-"$HOME/.ssh/id_ed25519"}
  SSH_DEADLINE_SECONDS=${HOMELAB_DEPLOYMENT_SSH_DEADLINE_SECONDS:-60}
  [[ $SSH_DEADLINE_SECONDS =~ ^[1-9][0-9]*$ ]] || {
    printf 'SSH deadline must be a positive whole number of seconds.\n' >&2
    return 1
  }
  TARGET=${HOMELAB_DEPLOYMENT_TARGET:-"operator@$NAS_ADDRESS"}
  SERVER=$NAS_ADDRESS
  EXPECTED_SHARES=(mediaBin smolBoy)
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
  GUEST_NAMESPACE=$(new_guest_namespace) || return 1
  GUEST_FIXTURE="$GUEST_MOUNTPOINT/$GUEST_NAMESPACE/round-trip.txt"
  expected="homelab guest SMB verification $GUEST_NAMESPACE"

  GUEST_MOUNT_ATTEMPTED=true
  if ! /sbin/mount_smbfs -N -o nobrowse,soft,nopassprompt -s \
    "//guest@$SERVER/$share" "$GUEST_MOUNTPOINT"; then
    cleanup_guest_resources || true
    printf 'guest mount failed for %s/%s\n' "$SERVER" "$share" >&2
    [[ -z $GUEST_CLEANUP_ERROR ]] || printf 'cleanup also failed: %s\n' "$GUEST_CLEANUP_ERROR" >&2
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

@test "the NAS becomes reachable over SSH within a finite deadline" {
  run wait_for_ssh
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
}

@test "the NAS has no failed systemd units" {
  run assert_systemd_healthy
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
}

@test "the NAS exposes an existing NixOS system generation" {
  run assert_active_generation
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
  [[ $output == *"active deployment generation: /nix/store/"* ]]
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
