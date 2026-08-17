#!/usr/bin/env bats

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  WORKDIR=$(mktemp -d)
  NIX_LOG="$WORKDIR/nix-args.log"
  FAIL_MATCH=''
  export NIX_LOG FAIL_MATCH
  cat >"$WORKDIR/nix" <<'SCRIPT'
#!/bin/sh
printf '%s\n' "$*" >>"$NIX_LOG"
if [ -n "${FAIL_MATCH:-}" ]; then
  case "$*" in *"$FAIL_MATCH"*) exit 42 ;; esac
fi
exit 0
SCRIPT
  chmod +x "$WORKDIR/nix"
}

teardown() { rm -rf "$WORKDIR"; }

@test "test runs fast non-live phases without VM, live access, or activation" {
  run make -rR --no-print-directory -C "$ROOT" test NIX="$WORKDIR/nix"
  [ "$status" -eq 0 ]
  grep -Fq 'run .#harness' "$NIX_LOG"
  grep -Fq 'tests/tooling/environment.bats' "$NIX_LOG"
  grep -Fq 'tests/agents/specbase-instruments.sh all' "$NIX_LOG"
  grep -Fq 'tests/specbase/current-bindings.sh all-local' "$NIX_LOG"
  run grep -Fq '.#checks.x86_64-linux.vm-tests' "$NIX_LOG"
  [ "$status" -ne 0 ]
  run grep -Eq 'switch|dry-activate|--target-host|.#verify' "$NIX_LOG"
  [ "$status" -ne 0 ]
}

@test "a failed fast phase makes test fail" {
  export FAIL_MATCH='tests/tooling/environment.bats'
  run make -rR --no-print-directory -C "$ROOT" test NIX="$WORKDIR/nix"
  [ "$status" -ne 0 ]
  run grep -Fq '.#checks.x86_64-linux.vm-tests' "$NIX_LOG"
  [ "$status" -ne 0 ]
}

@test "test-vm selects the fixed aggregate through the default store" {
  run make -rR --no-print-directory -C "$ROOT" test-vm NIX="$WORKDIR/nix"
  [ "$status" -eq 0 ]
  grep -Fq 'build --store ssh-ng://operator@10.10.10.11' "$NIX_LOG"
  grep -Fq -- '--eval-store auto --no-link .#checks.x86_64-linux.vm-tests' "$NIX_LOG"
}

@test "test-vm changes execution placement without changing derivation identity" {
  store='ssh-ng://ci@example.test?ssh-key=/tmp/key&system-features=kvm%20nixos-test'
  run make -rR --no-print-directory -C "$ROOT" test-vm NIX="$WORKDIR/nix" TEST_STORE="$store"
  [ "$status" -eq 0 ]
  grep -Fq "build --store $store" "$NIX_LOG"
  grep -Fq '.#checks.x86_64-linux.vm-tests' "$NIX_LOG"
}

@test "the fixed aggregate contains the isolation harness and Samba behavior VM" {
  flake_ref=${HOMELAB_FLAKE_REF:-"path:$ROOT"}
  aggregate=$(nix eval --raw "$flake_ref#checks.x86_64-linux.vm-tests.drvPath")
  isolation=$(nix eval --raw "$flake_ref#checks.x86_64-linux.vm-harness-private-network.drvPath")
  samba=$(nix eval --raw "$flake_ref#checks.x86_64-linux.nas-samba-vm.drvPath")
  graph=$(nix derivation show --recursive "$aggregate")
  jq -e --arg isolation "$isolation" --arg samba "$samba" \
    'has($isolation) and has($samba)' <<<"$graph" >/dev/null
}
