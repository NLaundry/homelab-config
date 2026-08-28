#!/usr/bin/env bats

# shellcheck source=tests/harness/operation-registry.sh
source "$BATS_TEST_DIRNAME/operation-registry.sh"

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  WORKDIR=$(mktemp -d)
  BIN="$WORKDIR/bin"
  CALL_LOG="$WORKDIR/calls.log"
  mkdir -p "$BIN"
  : >"$CALL_LOG"
  export CALL_LOG SPECBASE_STATUS=0 NIX_STATUS=0

  cat >"$BIN/specbase" <<'SCRIPT'
#!/bin/sh
printf 'specbase:%s\n' "$*" >>"$CALL_LOG"
exit "${SPECBASE_STATUS:-0}"
SCRIPT

  cat >"$BIN/nix" <<'SCRIPT'
#!/bin/sh
printf 'nix:%s\n' "$*" >>"$CALL_LOG"
exit "${NIX_STATUS:-0}"
SCRIPT

  chmod +x "$BIN/specbase" "$BIN/nix"
}

teardown() {
  rm -rf "$WORKDIR"
}

repository_digest() {
  (
    cd "$ROOT" || exit
    {
      printf '%s\n' flake.nix
      find specbase/specs -type f -print
    } | LC_ALL=C sort | while IFS= read -r file; do
      sha256sum "$file"
    done
  ) | sha256sum | awk '{ print $1 }'
}

run_lint() {
  assert_operation_registered "$ROOT/Makefile" lint || return 1
  make -rR --no-print-directory -C "$ROOT" lint \
    SPECBASE="$BIN/specbase" NIX="$BIN/nix"
}

@test "lint runs strict current-spec validation before flake evaluation" {
  before=$(repository_digest)
  run run_lint
  after=$(repository_digest)

  [ "$status" -eq 0 ]
  [ "$before" = "$after" ]
  [ "$(sed -n '1p' "$CALL_LOG")" = "specbase:validate --specs --strict" ]
  [ "$(sed -n '2p' "$CALL_LOG")" = "nix:flake check --no-update-lock-file --all-systems --no-build" ]
  [ "$(wc -l <"$CALL_LOG" | tr -d ' ')" -eq 2 ]
}

@test "a current-spec validation failure stops lint and preserves repository truth" {
  before=$(repository_digest)
  export SPECBASE_STATUS=23

  run run_lint
  after=$(repository_digest)

  [ "$status" -ne 0 ]
  [ "$before" = "$after" ]
  grep -Fxq 'specbase:validate --specs --strict' "$CALL_LOG"
  if grep -q '^nix:' "$CALL_LOG"; then
    printf 'flake check ran after failed current-spec validation\n' >&2
    return 1
  fi
}

@test "a flake-check failure independently makes lint fail" {
  before=$(repository_digest)
  export NIX_STATUS=29

  run run_lint
  after=$(repository_digest)

  [ "$status" -ne 0 ]
  [ "$before" = "$after" ]
  grep -Fxq 'specbase:validate --specs --strict' "$CALL_LOG"
  grep -Fxq 'nix:flake check --no-update-lock-file --all-systems --no-build' "$CALL_LOG"
}
