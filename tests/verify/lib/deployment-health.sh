#!/usr/bin/env bash

remote() {
  "$SSH_COMMAND" -o BatchMode=yes -o ConnectTimeout=5 \
    -i "$SSH_IDENTITY" "$TARGET" "$@"
}

wait_for_ssh() {
  local deadline=$(( SECONDS + SSH_DEADLINE_SECONDS )) last_diagnostic=''
  while (( SECONDS < deadline )); do
    if last_diagnostic=$(remote true 2>&1); then
      return 0
    fi
    sleep 1
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
