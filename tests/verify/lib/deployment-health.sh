#!/usr/bin/env bash

remote() {
  local status
  timeout --signal=KILL "${REMOTE_TIMEOUT_SECONDS:-$SSH_DEADLINE_SECONDS}s" \
    "$SSH_COMMAND" -o BatchMode=yes -o ConnectTimeout=5 \
    -i "$SSH_IDENTITY" "$TARGET" "$@" && return 0
  status=$?
  if (( status == 124 || status == 137 )); then
    printf 'SSH command timed out or was killed for %s\n' "$TARGET" >&2
  fi
  return "$status"
}

wait_for_ssh() {
  local deadline=$(( SECONDS + SSH_DEADLINE_SECONDS )) last_diagnostic='' remaining
  while (( SECONDS < deadline )); do
    remaining=$(( deadline - SECONDS ))
    (( remaining > 0 )) || break
    if last_diagnostic=$(REMOTE_TIMEOUT_SECONDS=$remaining remote true 2>&1); then
      return 0
    fi
    if (( SECONDS < deadline )); then sleep 1; fi
  done
  printf 'deployment reachability was not established for %s within %ss\nlast SSH diagnostic: %s\n' \
    "$TARGET" "$SSH_DEADLINE_SECONDS" "$last_diagnostic" >&2
  return 1
}

assert_systemd_healthy() {
  local failed_units
  if ! failed_units=$(remote 'systemctl list-units --state=failed --no-legend --plain' 2>&1); then
    printf 'deployment systemd health command failed for %s\nremote diagnostic:\n%s\n' \
      "$TARGET" "$failed_units" >&2
    return 1
  fi
  [[ -z $failed_units ]] || {
    printf 'deployment systemd health was not established for %s\nfailed units:\n%s\n' \
      "$TARGET" "$failed_units" >&2
    return 1
  }
}

assert_active_generation() {
  local active
  active=$(remote 'readlink -f /run/current-system') || {
    printf 'active generation could not be resolved for %s\n' "$TARGET" >&2
    return 1
  }
  [[ $active == /nix/store/*-nixos-system-* ]] || {
    printf 'active generation is not a NixOS system closure: %s\n' "$active" >&2
    return 1
  }
  remote "test -d '$active'" || {
    printf 'active generation path does not exist on %s: %s\n' "$TARGET" "$active" >&2
    return 1
  }
  printf 'active deployment generation: %s\n' "$active"
}
