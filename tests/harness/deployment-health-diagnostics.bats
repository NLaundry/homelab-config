#!/usr/bin/env bats

# Compact false-success checks for the live deployment helper.
# shellcheck disable=SC1091,SC2030,SC2031
source "$BATS_TEST_DIRNAME/../verify/lib/deployment-health.sh"

setup() {
  WORKDIR=$(mktemp -d)
  SSH_COMMAND="$WORKDIR/ssh"
  SSH_IDENTITY="$WORKDIR/key"
  SSH_DEADLINE_SECONDS=1
  TARGET='operator@fixture.invalid'
  cat >"$SSH_COMMAND" <<'SCRIPT'
#!/bin/sh
for argument in "$@"; do command=$argument; done
case ${FIXTURE_MODE:?} in
  unreachable) printf 'controlled timeout\n' >&2; exit 255 ;;
  failed-unit)
    case $command in
      'systemctl list-units --state=failed --no-legend --plain') printf 'fixture.service loaded failed failed\n' ;;
      *) exit 0 ;;
    esac ;;
  command-error) printf 'controlled transport failure\n' >&2; exit 255 ;;
  invalid-generation)
    case $command in 'readlink -f /run/current-system') printf '/tmp/not-a-system\n' ;; *) exit 0 ;; esac ;;
esac
SCRIPT
  chmod +x "$SSH_COMMAND"
  export SSH_COMMAND SSH_IDENTITY SSH_DEADLINE_SECONDS TARGET FIXTURE_MODE
}

teardown() { rm -rf "$WORKDIR"; }

@test "unreachable SSH cannot satisfy deployment reachability" {
  export FIXTURE_MODE=unreachable
  run wait_for_ssh
  [ "$status" -ne 0 ]
  [[ $output == *"deployment reachability was not established"* ]]
}

@test "a failed unit cannot satisfy systemd health" {
  export FIXTURE_MODE=failed-unit
  run assert_systemd_healthy
  [ "$status" -ne 0 ]
  [[ $output == *"fixture.service"* ]]
}

@test "a failed health command is not mistaken for an empty failed-unit set" {
  export FIXTURE_MODE=command-error
  run assert_systemd_healthy
  [ "$status" -ne 0 ]
  [[ $output == *"deployment systemd health command failed"* ]]
}

@test "an invalid current-system path cannot satisfy generation health" {
  export FIXTURE_MODE=invalid-generation
  run assert_active_generation
  [ "$status" -ne 0 ]
  [[ $output == *"not a NixOS system closure"* ]]
}
