#!/usr/bin/env bats

# shellcheck source=tests/harness/operation-registry.sh
source "$BATS_TEST_DIRNAME/operation-registry.sh"

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  VERIFY_RUNNER=${HOMELAB_VERIFY_RUNNER:?run this source through the flake-packaged harness}
  PASS_FIXTURE="$ROOT/tests/harness/fixtures/pass.bats"
  FAIL_FIXTURE="$ROOT/tests/harness/fixtures/fail.bats"
  SSH_FIXTURE="$ROOT/tests/harness/fixtures/ssh.bats"
  WORKDIR=$(mktemp -d)
  NIX_LOG="$WORKDIR/nix-args.log"
  export HOMELAB_VERIFY_RUNNER NIX_LOG

  cat >"$WORKDIR/nix" <<'SCRIPT'
#!/bin/sh
printf '%s\n' "$@" >"$NIX_LOG"
[ "$1" = run ]
[ "$2" = '.#verify' ]
[ "$3" = -- ]
shift 3
exec "$HOMELAB_VERIFY_RUNNER" "$@"
SCRIPT
  chmod +x "$WORKDIR/nix"
}

teardown() {
  rm -rf "$WORKDIR"
}

@test "the packaged runner selects the default live-verification suite without executing it" {
  run "$VERIFY_RUNNER" --list-default
  [ "$status" -eq 0 ]
  [[ $output == *"/tests/verify/suite.bats"* ]]
  [[ $output == *"/tests/verify/smb-fixtures.bats"* ]]
  [[ $output != *"/tests/verify/profiles/"* ]]
}

@test "the packaged Bats runner accepts a controlled passing fixture" {
  run "$VERIFY_RUNNER" "$PASS_FIXTURE"
  [ "$status" -eq 0 ]
  [[ $output == *"controlled passing Bats fixture"* ]]
}

@test "the packaged live runner supplies the selected SSH transport" {
  run "$VERIFY_RUNNER" "$SSH_FIXTURE"
  [ "$status" -eq 0 ]
  [[ $output == *"selected SSH transport is present"* ]]
}

@test "the packaged Bats runner propagates a controlled failing fixture" {
  run "$VERIFY_RUNNER" "$FAIL_FIXTURE"
  [ "$status" -ne 0 ]
  [[ $output == *"controlled failing Bats fixture"* ]]
}

@test "make verify propagates the selected Bats failure" {
  assert_operation_registered "$ROOT/Makefile" verify
  run make -rR --no-print-directory -C "$ROOT" verify \
    NIX="$WORKDIR/nix" "VERIFY_ARGS=$FAIL_FIXTURE"

  [ "$status" -ne 0 ]
  grep -Fxq 'run' "$NIX_LOG"
  grep -Fxq '.#verify' "$NIX_LOG"
  grep -Fxq -- '--' "$NIX_LOG"
  grep -Fxq "$FAIL_FIXTURE" "$NIX_LOG"
  [[ $output == *"controlled failing Bats fixture"* ]]
}
