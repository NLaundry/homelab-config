#!/usr/bin/env bats

# shellcheck source=tests/harness/operation-registry.sh
source "$BATS_TEST_DIRNAME/operation-registry.sh"

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  WORKDIR=$(mktemp -d)
  NIX_LOG="$WORKDIR/nix-args.log"
  NRB_MARKER="$WORKDIR/nrb-called"
  NIX_FAIL_MATCH=''
  NIX_FAIL_STATUS=42
  export NIX_LOG NRB_MARKER NIX_FAIL_MATCH NIX_FAIL_STATUS

  cat >"$WORKDIR/nix" <<'SCRIPT'
#!/bin/sh
{
  printf '%s' "$1"
  shift
  for argument in "$@"; do printf '\t%s' "$argument"; done
  printf '\n'
} >>"$NIX_LOG"

if [ -n "${NIX_FAIL_MATCH:-}" ]; then
  for argument in "$@"; do
    case $argument in
      *"$NIX_FAIL_MATCH"*) exit "${NIX_FAIL_STATUS:-42}" ;;
    esac
  done
fi
SCRIPT

  cat >"$WORKDIR/nixos-rebuild" <<'SCRIPT'
#!/bin/sh
: >"$NRB_MARKER"
exit 97
SCRIPT

  chmod +x "$WORKDIR/nix" "$WORKDIR/nixos-rebuild"
}

teardown() {
  rm -rf "$WORKDIR"
}

non_live_phase_registry() {
  local makefile=$1 database
  database=$(make -rR -f "$makefile" -pn help 2>/dev/null) || return 1
  awk '
    $1 == "NON_LIVE_PHASES" && $2 == ":=" {
      for (i = 3; i <= NF; i++) print $i
      exit
    }
  ' <<<"$database"
}

assert_non_live_phase_inventory() {
  local makefile=$1 actual expected
  actual=$(non_live_phase_registry "$makefile")
  expected=$(printf '%s\n' harness tooling agents current-bindings vm)
  [[ $actual == "$expected" ]] || {
    printf 'non-live phase inventory differs\nexpected:\n%s\nactual:\n%s\n' \
      "$expected" "$actual" >&2
    return 1
  }
}

assert_vm_aggregate_mapping() {
  local derivations_json=$1 vm_drv=$2
  jq -e --arg vm_drv "$vm_drv" 'has($vm_drv)' <<<"$derivations_json" >/dev/null || {
    printf 'VM aggregate does not reference the private-network runner: %s\n' "$vm_drv" >&2
    return 1
  }
}

run_test_operation() {
  assert_operation_registered "$ROOT/Makefile" test || return 1
  assert_non_live_phase_inventory "$ROOT/Makefile" || return 1
  make -rR --no-print-directory -C "$ROOT" test \
    NIX="$WORKDIR/nix" NRB="$WORKDIR/nixos-rebuild" "$@"
}

assert_all_phases_invoked() {
  grep -Fq $'run\t.#specbase\t--\tvalidate\t--specs\t--strict' "$NIX_LOG"
  grep -Fq $'flake\tcheck\t--all-systems\t--no-build' "$NIX_LOG"
  grep -Fq $'run\t.#harness' "$NIX_LOG"
  grep -Fq $'develop\t--command\tenv\tTEST_STORE=' "$NIX_LOG"
  grep -Fq $'bats\ttests/tooling/environment.bats' "$NIX_LOG"
  grep -Fq $'develop\t--command\ttests/agents/specbase-instruments.sh\tall' "$NIX_LOG"
  grep -Fq $'develop\t--command\ttests/specbase/current-bindings.sh\tall-local' "$NIX_LOG"
  grep -Fq $'build\t--store\tssh-ng://' "$NIX_LOG"
  grep -Fq $'\t--eval-store\tauto\t--no-link' "$NIX_LOG"
}

assert_fixed_derivation() {
  grep -Fq $'\t.#checks.x86_64-linux.vm-tests' "$NIX_LOG"
  ! grep -Fq '.#checks.x86_64-linux.not-the-suite' "$NIX_LOG"
}

assert_no_activation() {
  [ ! -e "$NRB_MARKER" ]
  ! grep -Eq '(^|\t)(switch|boot|dry-activate|--target-host)(\t|$)' "$NIX_LOG"
}

@test "test runs every registered non-live phase and the fixed VM aggregate" {
  run run_test_operation 'TEST_CHECK=.#checks.x86_64-linux.not-the-suite'

  [ "$status" -eq 0 ]
  assert_all_phases_invoked
  assert_fixed_derivation
  grep -Fq "ssh-ng://operator@10.10.10.11?ssh-key=$HOME/.ssh/id_ed25519&system-features=kvm%20nixos-test" "$NIX_LOG"
  assert_no_activation
}

@test "a missing non-live phase is rejected by an independent inventory" {
  sed 's/harness tooling agents current-bindings vm/harness agents current-bindings vm/' \
    "$ROOT/Makefile" >"$WORKDIR/Makefile"

  run assert_non_live_phase_inventory "$WORKDIR/Makefile"
  [ "$status" -ne 0 ]
  [[ $output == *"non-live phase inventory differs"* ]]
}

@test "the fixed aggregate contains the disposable private-network VM runner" {
  local flake_ref aggregate_drv vm_drv derivations_json
  flake_ref=${HOMELAB_FLAKE_REF:-"path:$ROOT"}
  aggregate_drv=$(nix eval --raw "$flake_ref#checks.x86_64-linux.vm-tests.drvPath")
  vm_drv=$(nix eval --raw "$flake_ref#checks.x86_64-linux.vm-harness-private-network.drvPath")
  derivations_json=$(nix derivation show --recursive "$aggregate_drv")

  run assert_vm_aggregate_mapping "$derivations_json" "$vm_drv"
  [ "$status" -eq 0 ]
}

@test "a removed VM runner is rejected by the aggregate-mapping check" {
  local flake_ref aggregate_drv vm_drv derivations_json drifted_json
  flake_ref=${HOMELAB_FLAKE_REF:-"path:$ROOT"}
  aggregate_drv=$(nix eval --raw "$flake_ref#checks.x86_64-linux.vm-tests.drvPath")
  vm_drv=$(nix eval --raw "$flake_ref#checks.x86_64-linux.vm-harness-private-network.drvPath")
  derivations_json=$(nix derivation show --recursive "$aggregate_drv")
  drifted_json=$(jq --arg vm_drv "$vm_drv" 'del(.[$vm_drv])' <<<"$derivations_json")

  run assert_vm_aggregate_mapping "$drifted_json" "$vm_drv"
  [ "$status" -ne 0 ]
  [[ $output == *"VM aggregate does not reference"* ]]
}

@test "a failed local phase stops test before the VM phase" {
  # `run` executes the function in a subshell that inherits this exported fixture.
  # shellcheck disable=SC2030
  export NIX_FAIL_MATCH=tests/tooling/environment.bats
  run run_test_operation

  [ "$status" -ne 0 ]
  grep -Fq $'run\t.#harness' "$NIX_LOG"
  grep -Fq 'tests/tooling/environment.bats' "$NIX_LOG"
  run grep -Fq '.#checks.x86_64-linux.vm-tests' "$NIX_LOG"
  [ "$status" -ne 0 ]
  assert_no_activation
}

@test "a failed aggregate derivation makes the complete test gate fail" {
  # See the exported-subshell fixture note in the preceding test.
  # shellcheck disable=SC2031
  export NIX_FAIL_MATCH=.#checks.x86_64-linux.vm-tests
  run run_test_operation

  [ "$status" -ne 0 ]
  assert_all_phases_invoked
  assert_fixed_derivation
  assert_no_activation
}

@test "an alternate compatible remote store changes placement but not derivation identity" {
  alternate='ssh-ng://ci@example.test?ssh-key=/tmp/ci-key&system-features=kvm%20nixos-test'
  run run_test_operation "TEST_STORE=$alternate" 'TEST_CHECK=.#checks.x86_64-linux.not-the-suite'

  [ "$status" -eq 0 ]
  assert_all_phases_invoked
  assert_fixed_derivation
  grep -Fq "$alternate" "$NIX_LOG"
  assert_no_activation
}
