#!/usr/bin/env bats

# bats file_tags=nas,smb-fixtures,controlled-residue
# shellcheck source=tests/verify/lib/run-namespace.sh
source "$BATS_TEST_DIRNAME/../lib/run-namespace.sh"
# shellcheck source=tests/verify/lib/suite-lock.sh
# shellcheck disable=SC1091
source "$BATS_TEST_DIRNAME/../lib/suite-lock.sh"

setup_file() {
  verification_acquire_suite_lock 900
}

teardown_file() {
  verification_release_suite_lock
}

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../../.." && pwd)"}
  CLIENT="$ROOT/tests/verify/lib/smb-fixture-client.sh"
  SERVER=${HOMELAB_NAS_ADDRESS:-10.10.10.11}
  AUTH_FILE=${HOMELAB_VERIFICATION_AUTH_FILE:-"$HOME/.config/homelab/verification-smb.auth"}
  VERIFICATION_RUN_ID=$(verification_new_run_id)
  export VERIFICATION_RUN_ID
}

@test "a controlled cleanup failure reports the exact residual run" {
  run "$CLIENT" transaction --server "$SERVER" --auth-file "$AUTH_FILE" \
    --run-id "$VERIFICATION_RUN_ID" --simulate-cleanup-failure
  [ "$status" -ne 0 ]
  [[ $output == *"controlled cleanup failure"* ]]
  [[ $output == *"residual run $VERIFICATION_RUN_ID"* ]]
  printf 'CONTROLLED_RESIDUAL_RUN=%s\n' "$VERIFICATION_RUN_ID"
}
