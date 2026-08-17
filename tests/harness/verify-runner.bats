#!/usr/bin/env bats

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  VERIFY_RUNNER=${HOMELAB_VERIFY_RUNNER:?run this source through the flake-packaged harness}
  FAIL_FIXTURE="$ROOT/tests/harness/fixtures/fail.bats"
  WORKDIR=$(mktemp -d)
  NIX_LOG="$WORKDIR/nix-args.log"
  export HOMELAB_VERIFY_RUNNER NIX_LOG
  cat >"$WORKDIR/nix" <<'SCRIPT'
#!/bin/sh
printf '%s\n' "$*" >>"$NIX_LOG"
shift 3
exec "$HOMELAB_VERIFY_RUNNER" "$@"
SCRIPT
  chmod +x "$WORKDIR/nix"
}

teardown() { rm -rf "$WORKDIR"; }

@test "the default runner selects only deployed behavior sources" {
  run "$VERIFY_RUNNER" --list-default
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | wc -l | tr -d ' ')" -eq 2 ]
  [[ $output == *"/tests/verify/deployment.bats"* ]]
  [[ $output == *"/tests/verify/nas-samba.bats"* ]]
  [[ $output != *"/tests/verify/profiles/"* ]]
}

@test "the packaged runner propagates a selected Bats failure" {
  run "$VERIFY_RUNNER" "$FAIL_FIXTURE"
  [ "$status" -ne 0 ]
  [[ $output == *"controlled failing Bats fixture"* ]]
}

@test "make verify remains non-activating and propagates the selected failure" {
  run make -rR --no-print-directory -C "$ROOT" verify \
    NIX="$WORKDIR/nix" "VERIFY_ARGS=$FAIL_FIXTURE"
  [ "$status" -ne 0 ]
  verify_output=$output
  grep -Fq 'run .#verify --' "$NIX_LOG"
  run grep -Eq 'switch|dry-activate|--target-host|nixos-rebuild' "$NIX_LOG"
  [ "$status" -ne 0 ]
  [[ $verify_output == *"controlled failing Bats fixture"* ]]
}
