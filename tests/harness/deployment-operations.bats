#!/usr/bin/env bats

# shellcheck source=tests/harness/operation-registry.sh
source "$BATS_TEST_DIRNAME/operation-registry.sh"

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  WORKDIR=$(mktemp -d)
  EVENT_LOG="$WORKDIR/events.log"
  VERIFY_ENV_LOG="$WORKDIR/verify-env.log"
  export EVENT_LOG VERIFY_ENV_LOG ACTIVATION_STATUS=0 VERIFY_STATUS=0

  cat >"$WORKDIR/nixos-rebuild" <<'SCRIPT'
#!/bin/sh
for argument in "$@"; do action=$argument; done
printf 'activate %s\n' "$action" >>"$EVENT_LOG"
exit "${ACTIVATION_STATUS:-0}"
SCRIPT

  cat >"$WORKDIR/nix" <<'SCRIPT'
#!/bin/sh
for argument in "$@"; do
  if [ "$argument" = '.#verify' ]; then
    printf 'verify\n' >>"$EVENT_LOG"
    printf 'target=%s\naddress=%s\nidentity=%s\n' \
      "${HOMELAB_DEPLOYMENT_TARGET:-}" \
      "${HOMELAB_NAS_ADDRESS:-}" \
      "${HOMELAB_DEPLOYMENT_SSH_IDENTITY:-}" >"$VERIFY_ENV_LOG"
    exit "${VERIFY_STATUS:-0}"
  fi
done
exit 0
SCRIPT

  chmod +x "$WORKDIR/nixos-rebuild" "$WORKDIR/nix"
}

teardown() {
  rm -rf "$WORKDIR"
}

require_text() {
  local text=$1 expected=$2 message=$3
  [[ $text == *"$expected"* ]] || {
    printf '%s: expected %s\ncommand: %s\n' "$message" "$expected" "$text" >&2
    return 1
  }
}

reject_text() {
  local text=$1 rejected=$2 message=$3
  [[ $text != *"$rejected"* ]] || {
    printf '%s: rejected %s\ncommand: %s\n' "$message" "$rejected" "$text" >&2
    return 1
  }
}

assert_deployment_operations() {
  local makefile=$1 target action output activation_line verify_line

  for target in deploy boot try dry build; do
    assert_operation_registered "$makefile" "$target" || return 1
    case $target in
      deploy) action='switch' ;;
      boot) action='boot' ;;
      try) action='test' ;;
      dry) action='dry-activate' ;;
      build) action='build' ;;
    esac

    output=$(make -rR --no-print-directory -f "$makefile" -n "$target") || return 1
    require_text "$output" "deployment-plan flake=.#nas" "$target omits resolved deployment plan" || return 1
    require_text "$output" "build-host=operator@10.10.10.11" "$target plan ignores build host" || return 1
    require_text "$output" "activation-host=operator@10.10.10.11" "$target plan ignores activation host" || return 1
    require_text "$output" "ssh-identity=$HOME/.ssh/id_ed25519" "$target plan omits SSH identity" || return 1
    require_text "$output" "privilege=--sudo" "$target plan omits privilege boundary" || return 1
    require_text "$output" "--flake .#nas" "$target ignores FLAKE" || return 1
    require_text "$output" "--build-host operator@10.10.10.11" "$target ignores TARGET for builds" || return 1
    printf '%s\n' "$output" | grep -Eq "[[:space:]]${action}$" || {
      printf '%s selects the wrong deployment action: %s\n' "$target" "$output" >&2
      return 1
    }

    if [[ $target != build ]]; then
      require_text "$output" "--target-host operator@10.10.10.11" "$target ignores TARGET for activation" || return 1
      require_text "$output" "--sudo" "$target omits operator escalation" || return 1
    fi

    if [[ $target == deploy || $target == try ]]; then
      require_text "$output" "HOMELAB_NAS_ADDRESS=\"10.10.10.11\"" "$target verification ignores selected address" || return 1
      require_text "$output" "HOMELAB_DEPLOYMENT_TARGET=\"operator@10.10.10.11\"" "$target verification ignores selected target" || return 1
      require_text "$output" "HOMELAB_DEPLOYMENT_SSH_IDENTITY=\"$HOME/.ssh/id_ed25519\"" "$target verification ignores selected identity" || return 1
      require_text "$output" "run .#verify --" "$target omits post-activation verification" || return 1
      require_text "$output" "No rollback was attempted" "$target omits failure-state diagnostic" || return 1
      activation_line=$(grep -nE "[[:space:]]${action}$" <<<"$output" | head -n 1 | cut -d: -f1)
      verify_line=$(grep -nF 'run .#verify --' <<<"$output" | head -n 1 | cut -d: -f1)
      (( activation_line < verify_line )) || {
        printf '%s runs verification before activation\n' "$target" >&2
        return 1
      }
    else
      reject_text "$output" "run .#verify --" "$target unexpectedly runs deployed verification" || return 1
    fi
  done

  for target in deploy boot try dry build; do
    output=$(make -rR --no-print-directory -f "$makefile" -n "$target" HOST=alternate)
    require_text "$output" "--flake .#alternate" "$target ignores HOST" || return 1

    output=$(make -rR --no-print-directory -f "$makefile" -n "$target" TARGET=operator@example.test)
    require_text "$output" "--build-host operator@example.test" "$target ignores TARGET for builds" || return 1
    if [[ $target != build ]]; then
      require_text "$output" "--target-host operator@example.test" "$target ignores TARGET for activation" || return 1
    fi

    output=$(make -rR --no-print-directory -f "$makefile" -n "$target" 'FLAKE=.#custom')
    require_text "$output" "--flake .#custom" "$target ignores FLAKE" || return 1

    output=$(make -rR --no-print-directory -f "$makefile" -n "$target" KEY=/tmp/alternate-identity)
    require_text "$output" "ssh-identity=/tmp/alternate-identity" "$target ignores KEY" || return 1
  done
}

run_deployment_operation() {
  local target=$1
  shift
  make -rR --no-print-directory -C "$ROOT" "$target" "$@" \
    NIX="$WORKDIR/nix" NRB="$WORKDIR/nixos-rebuild"
}

@test "deployment operations select every lifecycle action, verification boundary, and input" {
  run assert_deployment_operations "$ROOT/Makefile"
  [ "$status" -eq 0 ]
}

@test "an incorrect deployment action is detected without deployment" {
  awk '
    $0 == "\t$(REBUILD) switch" { print "\t$(REBUILD) boot"; next }
    { print }
  ' "$ROOT/Makefile" >"$WORKDIR/Makefile"

  run assert_deployment_operations "$WORKDIR/Makefile"
  [ "$status" -ne 0 ]
  [[ $output == *"deploy selects the wrong deployment action"* ]]
}

@test "an ignored deployment override is detected without deployment" {
  awk '
    {
      gsub(/--target-host \$\(TARGET\)/, "--target-host operator@10.10.10.11")
      print
    }
  ' "$ROOT/Makefile" >"$WORKDIR/Makefile"

  run assert_deployment_operations "$WORKDIR/Makefile"
  [ "$status" -ne 0 ]
  [[ $output == *"deploy ignores TARGET for activation"* ]]
}

@test "a target-specific build override regression is detected without deployment" {
  awk '
    /^build:/ { in_build = 1 }
    in_build && /^\t.*\$\(NRB\)/ {
      gsub(/--build-host \$\(TARGET\)/, "--build-host operator@10.10.10.11")
      in_build = 0
    }
    { print }
  ' "$ROOT/Makefile" >"$WORKDIR/Makefile"

  run assert_deployment_operations "$WORKDIR/Makefile"
  [ "$status" -ne 0 ]
  [[ $output == *"build ignores TARGET for builds"* ]]
}

@test "activation verification receives the resolved target address and identity" {
  run run_deployment_operation deploy TARGET=operator@example.test KEY=/tmp/alternate-identity
  [ "$status" -eq 0 ]
  grep -Fxq 'target=operator@example.test' "$VERIFY_ENV_LOG"
  grep -Fxq 'address=example.test' "$VERIFY_ENV_LOG"
  grep -Fxq 'identity=/tmp/alternate-identity' "$VERIFY_ENV_LOG"
}

@test "try and deploy verify strictly after successful activation" {
  local target action
  for target in try deploy; do
    : >"$EVENT_LOG"
    run run_deployment_operation "$target"
    [ "$status" -eq 0 ]
    action='test'
    [[ $target == deploy ]] && action=switch
    [ "$(<"$EVENT_LOG")" = $'activate '"$action"$'\nverify' ]
  done
}

@test "activation failure prevents deployed verification" {
  export ACTIVATION_STATUS=41
  run run_deployment_operation try

  [ "$status" -ne 0 ]
  [ "$(<"$EVENT_LOG")" = 'activate test' ]
  [[ $output != *"Running deployed verification"* ]]
}

@test "verification failure fails activation operation and reports no rollback" {
  export VERIFY_STATUS=42
  run run_deployment_operation deploy

  [ "$status" -ne 0 ]
  [ "$(<"$EVENT_LOG")" = $'activate switch\nverify' ]
  [[ $output == *"Activation succeeded, but deployed verification failed"* ]]
  [[ $output == *"No rollback was attempted"* ]]
}

@test "non-activating deployment operations never run deployed verification" {
  local target
  for target in boot dry build; do
    : >"$EVENT_LOG"
    run run_deployment_operation "$target"
    [ "$status" -eq 0 ]
    ! grep -Fxq verify "$EVENT_LOG"
  done
}
