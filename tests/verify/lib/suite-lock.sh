#!/usr/bin/env bash
set -euo pipefail

verification_acquire_suite_lock() {
  local timeout_seconds=${1:-600}
  local lock_parent=${HOMELAB_VERIFICATION_LOCK_DIR:-"$HOME/.cache/homelab"}
  local deadline=$(( SECONDS + timeout_seconds ))
  VERIFICATION_SUITE_LOCK="$lock_parent/verification-smb.lock"
  VERIFICATION_SUITE_LOCK_TOKEN=$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')
  export VERIFICATION_SUITE_LOCK VERIFICATION_SUITE_LOCK_TOKEN
  mkdir -p "$lock_parent"
  while ! mkdir "$VERIFICATION_SUITE_LOCK" 2>/dev/null; do
    if (( SECONDS >= deadline )); then
      printf 'verification suite lock remained busy for %ss: %s\n' \
        "$timeout_seconds" "$VERIFICATION_SUITE_LOCK" >&2
      return 1
    fi
    sleep 1
  done
  printf '%s\n' "$VERIFICATION_SUITE_LOCK_TOKEN" >"$VERIFICATION_SUITE_LOCK/owner"
}

verification_release_suite_lock() {
  local observed
  [[ -n ${VERIFICATION_SUITE_LOCK:-} && -n ${VERIFICATION_SUITE_LOCK_TOKEN:-} ]] || return 0
  [[ -f $VERIFICATION_SUITE_LOCK/owner && ! -L $VERIFICATION_SUITE_LOCK/owner ]] || {
    printf 'verification suite lock owner metadata is missing: %s\n' "$VERIFICATION_SUITE_LOCK" >&2
    return 1
  }
  observed=$(<"$VERIFICATION_SUITE_LOCK/owner")
  [[ $observed == "$VERIFICATION_SUITE_LOCK_TOKEN" ]] || {
    printf 'verification suite lock ownership changed: %s\n' "$VERIFICATION_SUITE_LOCK" >&2
    return 1
  }
  rm -- "$VERIFICATION_SUITE_LOCK/owner"
  rmdir "$VERIFICATION_SUITE_LOCK"
}
