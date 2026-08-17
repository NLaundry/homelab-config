#!/usr/bin/env bats

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  FLAKE_REF=${HOMELAB_FLAKE_REF:-"path:$ROOT"}
  WORKDIR=$(mktemp -d)
  CLIENT="$ROOT/tests/verify/lib/smb-fixture-client.sh"
  VERIFY_RUNNER=${HOMELAB_VERIFY_RUNNER:?run this source through the flake-packaged harness}
  SECRET_FILE="$WORKDIR/secret"
  printf 'controlled-secret-%(%s)T-%s' -1 "$BASHPID" >"$SECRET_FILE"
  chmod 0600 "$SECRET_FILE"
}

teardown() {
  rm -rf "$WORKDIR"
}

assert_secret_absent() {
  local pattern_file=$1
  shift
  local evidence
  for evidence in "$@"; do
    if grep -F -q -f "$pattern_file" -- "$evidence"; then
      printf 'secret material detected in evidence channel: %s\n' "$evidence" >&2
      return 1
    fi
  done
}

@test "the selected tester account has no interactive or administrative authority" {
  local user trusted_users
  user=$(nix eval --json "$FLAKE_REF#nixosConfigurations.nas.config.users.users.tester")
  trusted_users=$(nix eval --json "$FLAKE_REF#nixosConfigurations.nas.config.nix.settings.trusted-users")

  jq -e '
    .uid == 980 and .isSystemUser == true and .createHome == false and
    .hashedPassword == "!" and .extraGroups == [] and
    .openssh.authorizedKeys.keys == [] and (.shell | contains("-shadow-"))
  ' <<<"$user" >/dev/null
  run jq -e 'index("tester") != null or index("@verification") != null' \
    <<<"$trusted_users"
  [ "$status" -ne 0 ]
}

@test "the lifecycle procedure keeps credentials on standard input and outside traces" {
  local procedure
  procedure="$ROOT/tests/specbase/manual-verification.md"

  grep -Fq 'set +x' "$procedure"
  grep -Fq "smbpasswd -s -a tester" "$procedure"
  grep -Fq "mode-\`0600\` temporary file" "$procedure"
  grep -Fq 'atomically rename it' "$procedure"
  grep -Fq 'smbpasswd -d tester' "$procedure"
  grep -Fq "smbcontrol smbd close-share 'homelab-verification$'" "$procedure"
  run grep -Eq "smbpasswd[^\`\\n]*(--password|password=)" "$procedure"
  [ "$status" -ne 0 ]
}

@test "clean repository, derivation, argument, and output fixtures expose no secret" {
  local repository_file derivation_file arguments_file output_file
  repository_file="$WORKDIR/repository"
  derivation_file="$WORKDIR/derivation"
  arguments_file="$WORKDIR/arguments"
  output_file="$WORKDIR/output"
  printf '%s\n' 'username = tester' >"$repository_file"
  printf '%s\n' '/nix/store/example-verification-runner' >"$derivation_file"
  printf '%s\n' 'smbclient --authentication-file=/operator/private/path' >"$arguments_file"
  printf '%s\n' 'authentication failed for tester' >"$output_file"

  run assert_secret_absent "$SECRET_FILE" \
    "$repository_file" "$derivation_file" "$arguments_file" "$output_file"
  [ "$status" -eq 0 ]
}

@test "a controlled credential stays out of the real client output, argv, repository, and runner closure" {
  local auth_file output_file arguments_file verify_store argument
  auth_file="$WORKDIR/controlled.auth"
  output_file="$WORKDIR/client-output"
  arguments_file="$WORKDIR/client-arguments"
  {
    printf '%s\n' 'username = tester'
    printf 'password = '
    cat "$SECRET_FILE"
    printf '%s\n' 'domain = WORKGROUP'
  } >"$auth_file"
  chmod 0600 "$auth_file"

  run "$CLIENT" expect-denied --server 127.0.0.1 --auth-file "$auth_file"
  printf '%s\n' "$output" >"$output_file"
  [ "$status" -ne 0 ]
  [[ $output != *"$(<"$SECRET_FILE")"* ]]

  printf '%s\n' "$CLIENT" expect-denied --server 127.0.0.1 --auth-file "$auth_file" >"$arguments_file"
  for argument in "$CLIENT" expect-denied --server 127.0.0.1 --auth-file "$auth_file"; do
    [[ $argument != *"$(<"$SECRET_FILE")"* ]]
  done
  assert_secret_absent "$SECRET_FILE" "$output_file" "$arguments_file"

  run git -C "$ROOT" grep -I -F -f "$SECRET_FILE" -- .
  [ "$status" -eq 1 ]
  verify_store=${VERIFY_RUNNER%/bin/homelab-verify}
  run grep -R -I -F -q -f "$SECRET_FILE" -- "$verify_store"
  [ "$status" -eq 1 ]
}

@test "a secret in a tracked-file fixture is rejected" {
  local fixture
  fixture="$WORKDIR/tracked"
  printf 'password = ' >"$fixture"
  cat "$SECRET_FILE" >>"$fixture"

  run assert_secret_absent "$SECRET_FILE" "$fixture"
  [ "$status" -ne 0 ]
  [[ $output == *"tracked"* ]]
}

@test "a secret in a derivation fixture is rejected" {
  local fixture
  fixture="$WORKDIR/example.drv"
  cat "$SECRET_FILE" >"$fixture"

  run assert_secret_absent "$SECRET_FILE" "$fixture"
  [ "$status" -ne 0 ]
  [[ $output == *"example.drv"* ]]
}

@test "a secret in a process-argument fixture is rejected" {
  local fixture
  fixture="$WORKDIR/process-arguments"
  printf 'smbclient --password=' >"$fixture"
  cat "$SECRET_FILE" >>"$fixture"

  run assert_secret_absent "$SECRET_FILE" "$fixture"
  [ "$status" -ne 0 ]
  [[ $output == *"process-arguments"* ]]
}

@test "a secret in captured output is rejected" {
  local fixture
  fixture="$WORKDIR/captured-output"
  printf 'debug credential: ' >"$fixture"
  cat "$SECRET_FILE" >>"$fixture"

  run assert_secret_absent "$SECRET_FILE" "$fixture"
  [ "$status" -ne 0 ]
  [[ $output == *"captured-output"* ]]
}
