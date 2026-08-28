#!/usr/bin/env bats

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  LIB="$ROOT/tests/verify/lib/nas-samba-safety.sh"
  # shellcheck source=tests/verify/lib/nas-samba-safety.sh
  source "$LIB"
  WORKDIR=$(mktemp -d)
}

teardown() { rm -rf "$WORKDIR"; }

acquire_fixture() {
  GUEST_MOUNTPOINT="$WORKDIR/mount"
  GUEST_NAMESPACE=$(new_guest_namespace)
  GUEST_FIXTURE="$GUEST_MOUNTPOINT/$GUEST_NAMESPACE/round-trip.txt"
  GUEST_NAMESPACE_CREATED=true
  GUEST_MOUNT_ATTEMPTED=false
  mkdir -p "$(dirname "$GUEST_FIXTURE")"
  printf 'fixture\n' >"$GUEST_FIXTURE"
  export GUEST_MOUNTPOINT GUEST_NAMESPACE GUEST_FIXTURE \
    GUEST_NAMESPACE_CREATED GUEST_MOUNT_ATTEMPTED
}

cleanup_with_diagnostic() {
  cleanup_guest_resources || {
    printf '%s\n' "$GUEST_CLEANUP_ERROR" >&2
    return 1
  }
}

@test "concurrent verifier namespace tokens are 128-bit and unique" {
  local seen=$WORKDIR/seen token
  : >"$seen"
  for _ in $(seq 1 128); do
    token=$(new_guest_namespace)
    [[ $token =~ ^\.homelab-verify-[0-9a-f]{32}$ ]]
    ! grep -Fxq "$token" "$seen"
    printf '%s\n' "$token" >>"$seen"
  done
}

@test "post-acquisition assertion failure preserves failure and removes the exact namespace" {
  mountpoint="$WORKDIR/assertion-mount"
  run bash -c '
    set -euo pipefail
    source "$1"
    GUEST_MOUNTPOINT=$2
    GUEST_NAMESPACE=$(new_guest_namespace)
    GUEST_FIXTURE="$GUEST_MOUNTPOINT/$GUEST_NAMESPACE/round-trip.txt"
    GUEST_NAMESPACE_CREATED=true
    GUEST_MOUNT_ATTEMPTED=false
    mkdir -p "$(dirname "$GUEST_FIXTURE")"
    printf "fixture\n" >"$GUEST_FIXTURE"
    trap cleanup_guest_resources EXIT
    printf "controlled post-acquisition assertion failure\n" >&2
    exit 67
  ' _ "$LIB" "$mountpoint"
  [ "$status" -eq 67 ]
  [[ $output == *"controlled post-acquisition assertion failure"* ]]
  [ ! -e "$mountpoint" ]
}

@test "cleanup failure reports residue as failure" {
  acquire_fixture
  cat >"$WORKDIR/fail-rmdir" <<'EOF'
#!/bin/sh
exit 73
EOF
  chmod +x "$WORKDIR/fail-rmdir"
  export GUEST_RMDIR_COMMAND="$WORKDIR/fail-rmdir"
  run cleanup_with_diagnostic
  [ "$status" -ne 0 ]
  [[ $output == *"guest namespace cleanup failed"* ]]
  [[ $output == *"local mountpoint cleanup failed"* ]]
}

@test "TERM after acquisition executes exact cleanup" {
  mountpoint="$WORKDIR/signal-mount"
  run bash -c '
    set -euo pipefail
    source "$1"
    GUEST_MOUNTPOINT=$2
    GUEST_NAMESPACE=$(new_guest_namespace)
    GUEST_FIXTURE="$GUEST_MOUNTPOINT/$GUEST_NAMESPACE/round-trip.txt"
    GUEST_NAMESPACE_CREATED=true
    GUEST_MOUNT_ATTEMPTED=false
    mkdir -p "$(dirname "$GUEST_FIXTURE")"
    printf "fixture\n" >"$GUEST_FIXTURE"
    trap "cleanup_guest_resources; exit 143" TERM
    kill -TERM $$
  ' _ "$LIB" "$mountpoint"
  [ "$status" -eq 143 ]
  [ ! -e "$mountpoint" ]
}
