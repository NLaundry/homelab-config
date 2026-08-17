#!/usr/bin/env bats

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  FLAKE_REF=${HOMELAB_FLAKE_REF:-"path:$ROOT"}
  CURRENT_SYSTEM=$(nix eval --impure --raw --expr builtins.currentSystem)
  WORKDIR=$(mktemp -d)
}

teardown() {
  rm -rf "$WORKDIR"
}

supported_systems() {
  local systems_json
  systems_json=$(nix eval --json \
    "$FLAKE_REF#packages.$CURRENT_SYSTEM.repo-tools.passthru.supportedSystems") || {
    printf 'failed to evaluate supported operator systems\n' >&2
    return 1
  }
  jq -e 'type == "array" and length > 0' <<<"$systems_json" >/dev/null || {
    printf 'supported operator system list is empty or invalid\n' >&2
    return 1
  }
  jq -r '.[]' <<<"$systems_json"
}

system_inventory() {
  grep -Ev '^[[:space:]]*(#|$)' "$ROOT/nix/operator-systems.txt"
}

direct_commands() {
  local commands_json
  commands_json=$(nix eval --json \
    "$FLAKE_REF#packages.$CURRENT_SYSTEM.repo-tools.passthru.directCommands") || {
    printf 'failed to evaluate direct command registry\n' >&2
    return 1
  }
  jq -e 'type == "array" and length > 0' <<<"$commands_json" >/dev/null || {
    printf 'direct command registry is empty or invalid\n' >&2
    return 1
  }
  jq -r '.[]' <<<"$commands_json"
}

inventory_commands() {
  grep -Ev '^[[:space:]]*(#|$)' "$ROOT/nix/direct-commands.txt"
}

registered_operations() {
  local makefile=$1 database
  database=$(make -rR -f "$makefile" -pn help 2>/dev/null) || {
    printf 'failed to inspect registered Make operations\n' >&2
    return 1
  }
  awk '
    $1 == "OPERATIONS" && $2 == ":=" {
      for (i = 3; i <= NF; i++) print $i
      exit
    }
  ' <<<"$database"
}

operation_recipe_commands() {
  local makefile=$1 operations recipes
  operations=$(registered_operations "$makefile")
  [[ -n $operations ]] || {
    printf 'registered Make operation list is empty\n' >&2
    return 1
  }
  # Intentional word splitting: Make targets cannot contain whitespace.
  # shellcheck disable=SC2086
  recipes=$(make -rR --no-print-directory -n -f "$makefile" \
    $operations 2>/dev/null) || {
    printf 'failed to dry-run registered Make operations\n' >&2
    return 1
  }

  awk '
    function inspect(segment, fields, token) {
      gsub(/^[[:space:]@+-]+/, "", segment)
      while (segment ~ /^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+/) {
        sub(/^[^[:space:]]+[[:space:]]+/, "", segment)
      }
      if (segment == "") return
      split(segment, fields, /[[:space:]]+/)
      token = fields[1]
      if (token == "env" || token == "command" || token == "exec" ||
          token == "if" || token == "then" || token == "elif" ||
          token == "else" || token == "while" || token == "until" ||
          token == "do" || token == "!") {
        sub(/^[^[:space:]]+[[:space:]]+/, "", segment)
        inspect(segment)
        return
      }
      if (token == "for" || token == "case" || token == "fi" ||
          token == "done" || token == "esac" || token == "cd" ||
          token == "export" || token == "printf" || token == "read" ||
          token == "set" || token == "shift" || token == "test" ||
          token == "true" || token == "false" || token == "unset" ||
          token == "wait" || token == "exit" || token == "{" ||
          token == "}" || token == "\\" || token == ":" || token == "[") return
      print token
    }
    {
      line = $0
      gsub(/&&/, ";", line)
      gsub(/\|\|/, ";", line)
      count = split(line, segments, /[;|]/)
      for (i = 1; i <= count; i++) inspect(segments[i])
    }
  ' <<<"$recipes" | awk '!seen[$0]++'
}

lines_json() {
  jq -Rsc 'split("\n") | map(select(length > 0)) | sort | unique'
}

assert_same_command_inventory() {
  local inventory=$1 registry=$2 inventory_json registry_json
  inventory_json=$(printf '%s\n' "$inventory" | lines_json)
  registry_json=$(printf '%s\n' "$registry" | lines_json)
  [[ $inventory_json == "$registry_json" ]] || {
    printf 'direct command inventory and Nix registry differ\ninventory: %s\nregistry: %s\n' \
      "$inventory_json" "$registry_json" >&2
    return 1
  }
}

assert_same_system_inventory() {
  local inventory=$1 implementation=$2 inventory_json implementation_json
  inventory_json=$(printf '%s\n' "$inventory" | lines_json)
  implementation_json=$(printf '%s\n' "$implementation" | lines_json)
  [[ $inventory_json == "$implementation_json" ]] || {
    printf 'operator-system inventory and Nix implementation differ\ninventory: %s\nimplementation: %s\n' \
      "$inventory_json" "$implementation_json" >&2
    return 1
  }
}

assert_operation_commands_registered() {
  local makefile=$1 registry=$2 commands command_name
  commands=$(operation_recipe_commands "$makefile")
  [[ -n $commands ]] || {
    printf 'registered Make operations expose no auditable commands\n' >&2
    return 1
  }
  while IFS= read -r command_name; do
    if [[ $command_name == nix ]] || grep -Fxq "$command_name" <<<"$registry"; then
      continue
    fi
    printf 'operation command is neither Nix-managed nor an explicit bootstrap: %s\n' \
      "$command_name" >&2
    return 1
  done <<<"$commands"
}

assert_commands_available() {
  local command_name command_path
  for command_name in "$@"; do
    command_path=$(command -v "$command_name" 2>/dev/null) || {
      printf 'declared direct command is missing: %s\n' "$command_name" >&2
      return 1
    }
    [[ $command_path == /nix/store/* ]] || {
      printf 'declared direct command is ambient rather than Nix-provided: %s -> %s\n' \
        "$command_name" "$command_path" >&2
      return 1
    }
  done
}

assert_shell_uses_repo_tools() {
  local shell_json=$1 repo_tools_drv=$2
  jq -e --arg repo_tools_drv "$repo_tools_drv" '
    to_entries as $entries |
    ($entries | length == 1) and
    ($entries[0].value.inputDrvs | has($repo_tools_drv))
  ' <<<"$shell_json" >/dev/null || {
    printf 'default shell derivation does not consume repo-tools: %s\n' \
      "$repo_tools_drv" >&2
    return 1
  }
}

build_tooling_check() {
  local system=$1
  local attr="$FLAKE_REF#checks.$system.tooling-environment"
  if [[ $system == "$CURRENT_SYSTEM" ]]; then
    nix build --no-link "$attr"
  elif [[ -n ${TEST_STORE:-} ]]; then
    nix build --store "$TEST_STORE" --eval-store auto --no-link "$attr"
  else
    nix build --no-link "$attr"
  fi
}

@test "repo-tools, default shell, and native contract evaluate for every supported system" {
  local systems expected_systems system
  systems=$(supported_systems)
  expected_systems=$(system_inventory)
  [ -n "$systems" ]
  [ -n "$expected_systems" ]
  assert_same_system_inventory "$expected_systems" "$systems"

  while IFS= read -r system; do
    run nix eval --raw "$FLAKE_REF#packages.$system.repo-tools.drvPath"
    [ "$status" -eq 0 ]
    [[ $output == /nix/store/*-homelab-repo-tools.drv ]]

    run nix eval --raw "$FLAKE_REF#devShells.$system.default.drvPath"
    [ "$status" -eq 0 ]
    [[ $output == /nix/store/*-homelab-config.drv ]]

    run nix eval --raw "$FLAKE_REF#checks.$system.tooling-environment.drvPath"
    [ "$status" -eq 0 ]
    [[ $output == /nix/store/*-homelab-tooling-environment.drv ]]

    run nix eval --json \
      "$FLAKE_REF#packages.$system.repo-tools.passthru.platformAdapters"
    [ "$status" -eq 0 ]
    if [[ $system == "aarch64-darwin" ]]; then
      run jq -e '. == {"ssh":"/usr/bin/ssh"}' <<<"$output"
    else
      run jq -e '. == {}' <<<"$output"
    fi
    [ "$status" -eq 0 ]
  done <<<"$systems"
}

@test "the native repo-tools contract executes on every supported system" {
  local systems system
  systems=$(supported_systems)
  [ -n "$systems" ]

  while IFS= read -r system; do
    run build_tooling_check "$system"
    if [ "$status" -ne 0 ]; then
      printf 'native tooling check failed for %s:\n%s\n' "$system" "$output" >&2
    fi
    [ "$status" -eq 0 ]
  done <<<"$systems"
}

@test "the Darwin SSH command is a bounded adapter to the platform transport" {
  if [[ $CURRENT_SYSTEM != "aarch64-darwin" ]]; then
    skip "Darwin-only platform adapter"
  fi

  run nix eval --raw \
    "$FLAKE_REF#packages.$CURRENT_SYSTEM.repo-tools.passthru.platformAdapters.ssh"
  [ "$status" -eq 0 ]
  [ "$output" = "/usr/bin/ssh" ]
  [[ $(command -v ssh) == /nix/store/* ]]

  run ssh -V
  [ "$status" -eq 0 ]
  local adapter_version=$output
  run /usr/bin/ssh -V
  [ "$status" -eq 0 ]
  [ "$output" = "$adapter_version" ]
}

@test "the current development shell supplies every declared direct command" {
  local commands
  [ -n "${IN_NIX_SHELL:-}" ]
  commands=$(direct_commands)
  [ -n "$commands" ]
  # Intentional word splitting: command names cannot contain whitespace.
  # shellcheck disable=SC2086
  run assert_commands_available $commands
  [ "$status" -eq 0 ]
}

@test "registered Make operations use only managed or explicit bootstrap commands" {
  local registry
  registry=$(direct_commands)
  run assert_operation_commands_registered "$ROOT/Makefile" "$registry"
  [ "$status" -eq 0 ]
}

@test "the independent command inventory matches the Nix package registry" {
  local inventory registry
  inventory=$(inventory_commands)
  registry=$(direct_commands)
  run assert_same_command_inventory "$inventory" "$registry"
  [ "$status" -eq 0 ]
}

@test "the Nix-packaged Specbase CLI reports the selected compatible release" {
  run specbase --version
  [ "$status" -eq 0 ]
  [ "$output" = "1.6.0" ]
  [[ $(command -v specbase) == /nix/store/* ]]
}

@test "every default shell derivation directly consumes repo-tools" {
  local systems system repo_tools_drv shell_drv shell_json
  systems=$(supported_systems)
  [ -n "$systems" ]

  while IFS= read -r system; do
    repo_tools_drv=$(nix eval --raw "$FLAKE_REF#packages.$system.repo-tools.drvPath")
    shell_drv=$(nix eval --raw "$FLAKE_REF#devShells.$system.default.drvPath")
    shell_json=$(nix derivation show "$shell_drv")
    assert_shell_uses_repo_tools "$shell_json" "$repo_tools_drv"
  done <<<"$systems"
}

@test "a controlled missing direct command is rejected" {
  run assert_commands_available definitely-not-a-homelab-command
  [ "$status" -ne 0 ]
  [[ $output == *"declared direct command is missing"* ]]
}

@test "controlled direct-command inventory drift is rejected" {
  local registry drifted_inventory
  registry=$(direct_commands)
  drifted_inventory="${registry}"$'\nfixture-unregistered-command'
  run assert_same_command_inventory "$drifted_inventory" "$registry"
  [ "$status" -ne 0 ]
  [[ $output == *"direct command inventory and Nix registry differ"* ]]
}

@test "a controlled unregistered Make operation command is rejected" {
  local fixture=$WORKDIR/Makefile registry
  cp "$ROOT/Makefile" "$fixture"
  cat >>"$fixture" <<'EOF'

OPERATIONS += fixture-unregistered
fixture-unregistered:
	curl --version
EOF
  registry=$(direct_commands)
  run assert_operation_commands_registered "$fixture" "$registry"
  [ "$status" -ne 0 ]
  [[ $output == *"neither Nix-managed nor an explicit bootstrap: curl"* ]]
}

@test "a controlled supported-system removal is rejected" {
  local inventory drifted_implementation
  inventory=$(system_inventory)
  drifted_implementation=$(grep -Fvx 'x86_64-linux' <<<"$inventory")
  run assert_same_system_inventory "$inventory" "$drifted_implementation"
  [ "$status" -ne 0 ]
  [[ $output == *"operator-system inventory and Nix implementation differ"* ]]
}

@test "controlled default-shell input drift is rejected" {
  fixture='{"/nix/store/fixture-shell.drv":{"inputDrvs":{"/nix/store/other-tools.drv":{"outputs":["out"]}}}}'
  run assert_shell_uses_repo_tools "$fixture" /nix/store/fixture-repo-tools.drv
  [ "$status" -ne 0 ]
  [[ $output == *"does not consume repo-tools"* ]]
}

@test "managed commands do not resolve through Homebrew or global npm" {
  local command_name command_path
  for command_name in specbase bats make jq yq shellcheck shfmt ssh ansible; do
    command_path=$(command -v "$command_name")
    [[ $command_path == /nix/store/* ]]
    [[ $command_path != /opt/homebrew/* ]]
    [[ $command_path != "$HOME"/.npm/* ]]
  done
}
