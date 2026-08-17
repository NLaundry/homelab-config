#!/usr/bin/env bats

# bats file_tags=deployment,nas
# Exported fixture controls are intentionally inherited by Bats `run` subshells.
# shellcheck disable=SC2030,SC2031

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  NAS_ADDRESS=${HOMELAB_NAS_ADDRESS:-"$(yq -r '.all.children.nas.hosts.nasty.ansible_host' "$ROOT/ansible/inventory.yml")"}
  SSH_COMMAND=${HOMELAB_DEPLOYMENT_SSH_COMMAND:-ssh}
  SSH_IDENTITY=${HOMELAB_DEPLOYMENT_SSH_IDENTITY:-"$HOME/.ssh/id_ed25519"}
  SSH_DEADLINE_SECONDS=${HOMELAB_DEPLOYMENT_SSH_DEADLINE_SECONDS:-60}
  TARGET="operator@$NAS_ADDRESS"
  WORKDIR=$(mktemp -d)
}

teardown() {
  rm -rf "$WORKDIR"
}

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

install_fake_ssh() {
  cat >"$WORKDIR/ssh" <<'SCRIPT'
#!/bin/sh
for argument in "$@"; do command=$argument; done
case ${FIXTURE_MODE:?} in
  unreachable)
    printf 'controlled SSH timeout\n' >&2
    exit 255
    ;;
  failed-unit)
    case $command in
      'systemctl list-units --state=failed --no-legend --plain') printf 'fixture.service loaded failed failed\n'; exit 0 ;;
      *) exit 0 ;;
    esac
    ;;
  systemd-command-error)
    printf 'controlled remote command transport failure\n' >&2
    exit 255
    ;;
  invalid-generation)
    case $command in
      'readlink -f /run/current-system') printf '/tmp/not-a-system\n'; exit 0 ;;
      *) exit 0 ;;
    esac
    ;;
  *) exit 2 ;;
esac
SCRIPT
  chmod +x "$WORKDIR/ssh"
  SSH_COMMAND="$WORKDIR/ssh"
  export SSH_COMMAND FIXTURE_MODE
}

@test "the activated NAS becomes reachable over SSH within a finite deadline" {
  run wait_for_ssh
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
}

@test "the activated NAS has no failed systemd units" {
  run assert_systemd_healthy
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
}

@test "the activated NAS exposes an existing NixOS system generation" {
  run assert_active_generation
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
  [[ $output == *"active deployment generation: /nix/store/"* ]]
}

@test "an unreachable SSH fixture fails with the reachability check name and final diagnostic" {
  export FIXTURE_MODE=unreachable SSH_DEADLINE_SECONDS=1
  install_fake_ssh
  run wait_for_ssh
  [ "$status" -ne 0 ]
  [[ $output == *"deployment reachability was not established"* ]]
  [[ $output == *"controlled SSH timeout"* ]]
}

@test "a failed-unit fixture fails with actionable unit output" {
  export FIXTURE_MODE=failed-unit
  install_fake_ssh
  run assert_systemd_healthy
  [ "$status" -ne 0 ]
  [[ $output == *"deployment systemd health was not established"* ]]
  [[ $output == *"fixture.service"* ]]
}

@test "a failed systemd command is distinct from a non-empty failed-unit set" {
  export FIXTURE_MODE=systemd-command-error
  install_fake_ssh
  run assert_systemd_healthy
  [ "$status" -ne 0 ]
  [[ $output == *"deployment systemd health command failed"* ]]
  [[ $output == *"controlled remote command transport failure"* ]]
}

@test "an invalid current-system fixture fails with the observed path" {
  export FIXTURE_MODE=invalid-generation
  install_fake_ssh
  run assert_active_generation
  [ "$status" -ne 0 ]
  [[ $output == *"active generation is not a NixOS system closure: /tmp/not-a-system"* ]]
}
