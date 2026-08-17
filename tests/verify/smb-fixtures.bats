#!/usr/bin/env bats

# bats file_tags=nas,smb-fixtures
# shellcheck source=tests/verify/lib/smb-fixture-client.sh
source "$BATS_TEST_DIRNAME/lib/smb-fixture-client.sh"
# shellcheck source=tests/verify/lib/suite-lock.sh
source "$BATS_TEST_DIRNAME/lib/suite-lock.sh"

setup_file() {
  verification_acquire_suite_lock 900
}

teardown_file() {
  verification_release_suite_lock
}

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  CLIENT="$ROOT/tests/verify/lib/smb-fixture-client.sh"
  SERVER=${HOMELAB_NAS_ADDRESS:-10.10.10.11}
  AUTH_FILE=${HOMELAB_VERIFICATION_AUTH_FILE:-"$HOME/.config/homelab/verification-smb.auth"}
  RETIRED_AUTH_FILE=${HOMELAB_VERIFICATION_RETIRED_AUTH_FILE:-"$HOME/.config/homelab/verification-smb.retired.auth"}
  ORDINARY_SHARES="$ROOT/nix/ordinary-smb-shares.txt"
  VERIFICATION_RUN_ID=$(verification_new_run_id)
  export VERIFICATION_RUN_ID
}

assert_endpoint_reachable() {
  local preflight_run_id
  preflight_run_id=$(verification_new_run_id)
  "$CLIENT" transaction --server "$SERVER" \
    --auth-file "$AUTH_FILE" --run-id "$preflight_run_id" >/dev/null || {
    printf 'current-credential endpoint preflight failed: %s\n' "$preflight_run_id" >&2
    return 1
  }
}

@test "the hidden endpoint rejects guest access" {
  assert_endpoint_reachable
  run "$CLIENT" expect-denied --server "$SERVER"
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
  [[ $output == *"authorization denied as expected"* ]]
}

@test "the hidden endpoint rejects the retired tester credential" {
  assert_endpoint_reachable
  [ -f "$RETIRED_AUTH_FILE" ]
  [ ! -L "$RETIRED_AUTH_FILE" ]
  run "$CLIENT" expect-denied --server "$SERVER" \
    --auth-file "$RETIRED_AUTH_FILE"
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
  [[ $output == *"authorization denied as expected"* ]]
}

@test "the tester credential is denied by every ordinary share" {
  local share
  assert_endpoint_reachable
  while IFS= read -r share; do
    [[ -n $share && $share != \#* ]] || continue
    run "$CLIENT" expect-denied --server "$SERVER" --share "$share" --auth-file "$AUTH_FILE"
    if [ "$status" -ne 0 ]; then printf '%s: %s\n' "$share" "$output" >&2; fi
    [ "$status" -eq 0 ]
    [[ $output == *"authorization denied as expected"* ]]
  done <"$ORDINARY_SHARES"
}

@test "generic local permission failure is not classified as remote authorization denial" {
  local diagnostics
  diagnostics=$(mktemp)
  printf '%s\n' 'local helper: Permission denied' >"$diagnostics"
  run is_authorization_denial "$diagnostics"
  rm -f "$diagnostics"
  [ "$status" -ne 0 ]
}

@test "transport failure is not misreported as authorization denial" {
  run "$CLIENT" expect-denied --server 127.0.0.1
  [ "$status" -ne 0 ]
  [[ $output == *"non-authorization reason"* ]]
}

@test "a malformed authentication file is not misreported as authorization denial" {
  local malformed
  malformed=$(mktemp)
  chmod 0600 "$malformed"
  printf '%s\n' 'username = tester' >"$malformed"
  run "$CLIENT" expect-denied --server "$SERVER" --auth-file "$malformed"
  rm -f "$malformed"
  [ "$status" -ne 0 ]
  [[ $output == *"non-authorization reason"* ]]
}

@test "the current tester credential completes and cleans a fixture transaction" {
  run "$CLIENT" transaction --server "$SERVER" \
    --auth-file "$AUTH_FILE" --run-id "$VERIFICATION_RUN_ID"
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
  [[ $output == *"verification transaction passed and cleaned: $VERIFICATION_RUN_ID"* ]]
}

@test "a duplicate namespace is rejected without modifying pre-existing state" {
  run "$CLIENT" collision --server "$SERVER" \
    --auth-file "$AUTH_FILE" --run-id "$VERIFICATION_RUN_ID"
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
  [[ $output == *"duplicate namespace rejected without modifying existing state"* ]]
}

@test "a controlled assertion failure preserves the failure and still cleans its namespace" {
  run "$CLIENT" transaction --server "$SERVER" \
    --auth-file "$AUTH_FILE" --run-id "$VERIFICATION_RUN_ID" --fail-after-create
  [ "$status" -ne 0 ]
  if [[ $output != *"controlled assertion failure"* ]]; then printf '%s\n' "$output" >&2; fi
  [[ $output == *"controlled assertion failure"* ]]
  [[ $output == *"$VERIFICATION_RUN_ID"* ]]
  if [[ $output == *"cleanup also failed"* ]]; then printf '%s\n' "$output" >&2; fi
  [[ $output != *"cleanup also failed"* ]]
}
