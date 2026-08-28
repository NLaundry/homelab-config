#!/usr/bin/env bats

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  FLAKE_REF=${HOMELAB_FLAKE_REF:-"path:$ROOT"}
  WORKDIR=$(mktemp -d)
}

teardown() { rm -rf "$WORKDIR"; }

registry_json() {
  nix eval --no-update-lock-file --json \
    "$FLAKE_REF#checks.x86_64-linux.vm-tests.publicRegistry"
}

leaf_drv_paths_json() {
  nix eval --no-update-lock-file --json \
    "$FLAKE_REF#checks.x86_64-linux.vm-tests.leafDrvPaths"
}

assert_registry_contract() {
  local registry=$1
  jq -e '
    type == "object" and length > 0 and
    all(to_entries[];
      (.key | test("^[a-z0-9-]+$")) and
      (.value.aggregateName | type == "string" and length > 0) and
      (.value.source | type == "string" and startswith("tests/") and endswith(".nix")) and
      .value.disposable == true and
      .value.nonActivating == true and
      .value.privateNetwork == true)
  ' <<<"$registry" >/dev/null || {
    printf 'VM registry contains an undeclared, non-disposable, activating, or non-private subject: %s\n' "$registry" >&2
    return 1
  }
}

assert_registered_sources() {
  local registry=$1 name source
  while IFS=$'\t' read -r name source; do
    [[ -f "$ROOT/$source" ]] || {
      printf 'registered VM source is missing: %s -> %s\n' "$name" "$source" >&2
      return 1
    }
    grep -Fq 'pkgs.testers.runNixOSTest' "$ROOT/$source" || {
      printf 'registered VM subject is not a disposable NixOS test: %s\n' "$name" >&2
      return 1
    }
    grep -Fq 'qemu.forceAccel = true;' "$ROOT/$source" || {
      printf 'registered VM subject does not require the selected KVM boundary: %s\n' "$name" >&2
      return 1
    }
    grep -Fq 'qemu.networkingOptions = lib.mkForce [ ];' "$ROOT/$source" || {
      printf 'registered VM subject permits an implicit QEMU interface: %s\n' "$name" >&2
      return 1
    }
    grep -Fq 'restrictNetwork = true;' "$ROOT/$source" || {
      printf 'registered VM subject does not restrict host network access: %s\n' "$name" >&2
      return 1
    }
  done < <(jq -r 'to_entries[] | [.key,.value.source] | @tsv' <<<"$registry")
}

@test "every registered VM subject is disposable, non-activating, and private" {
  registry=$(registry_json)
  run assert_registry_contract "$registry"
  [ "$status" -eq 0 ]
  run assert_registered_sources "$registry"
  [ "$status" -eq 0 ]
}

@test "the fixed aggregate is derived from every registered VM leaf" {
  registry=$(registry_json)
  leaf_paths=$(leaf_drv_paths_json)
  aggregate=$(nix eval --no-update-lock-file --raw \
    "$FLAKE_REF#checks.x86_64-linux.vm-tests.drvPath")
  graph=$(nix derivation show --recursive "$aggregate")

  run jq -e --argjson registry "$registry" --argjson leaves "$leaf_paths" '
    . as $graph |
    (($registry | keys | sort) == ($leaves | keys | sort)) and
    ([$leaves[] as $leaf | $graph | has($leaf)] | all)
  ' <<<"$graph"
  [ "$status" -eq 0 ]
}

@test "a controlled non-private registry entry is rejected" {
  registry=$(registry_json)
  mutant=$(jq '.[keys[0]].privateNetwork = false' <<<"$registry")
  run assert_registry_contract "$mutant"
  [ "$status" -ne 0 ]
  [[ $output == *"non-private subject"* ]]
}

@test "a controlled implicit-interface declaration is rejected" {
  registry=$(registry_json)
  source=$(jq -r '.[keys[0]].source' <<<"$registry")
  mkdir -p "$WORKDIR/$(dirname "$source")"
  sed '/qemu.networkingOptions = lib.mkForce \[ \];/d' "$ROOT/$source" >"$WORKDIR/$source"
  old_root=$ROOT
  ROOT=$WORKDIR
  run assert_registered_sources "$registry"
  ROOT=$old_root
  [ "$status" -ne 0 ]
  [[ $output == *"permits an implicit QEMU interface"* ]]
}
