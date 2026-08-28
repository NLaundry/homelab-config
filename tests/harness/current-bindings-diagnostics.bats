#!/usr/bin/env bats

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  # shellcheck source=tests/specbase/current-bindings.sh
  source "$ROOT/tests/specbase/current-bindings.sh"
  WORKDIR=$(mktemp -d)
  VALID_NAS='{"pools":["mediaBin","smolBoy"],"hostId":"007f0200","forceImportRoot":false,"zfsSupported":true,"stateVersion":"26.05","targetSystem":"x86_64-linux"}'
  VALID_OPERATOR='{"isNormalUser":true,"extraGroups":["wheel"],"authorizedKeys":["ssh-ed25519 fixture"],"wheelNeedsPassword":false}'
  VALID_KERNEL='{"targetSystem":"x86_64-linux","kernelVersion":"6.18.42","kernelDrvPath":"/nix/store/kernel.drv","zfsModuleAttribute":"zfs_2_4","zfsModuleDrvPath":"/nix/store/zfs.drv","zfsModuleBroken":false,"toplevelDrvPath":"/nix/store/system.drv"}'
}

teardown() { rm -rf "$WORKDIR"; }

@test "valid projected NAS, operator, and kernel/ZFS records conform" {
  run assert_nas_configuration_json "$VALID_NAS"
  [ "$status" -eq 0 ]
  run assert_operator_configuration_json "$VALID_OPERATOR"
  [ "$status" -eq 0 ]
  run assert_kernel_zfs_projection_json "$VALID_KERNEL"
  [ "$status" -eq 0 ]
}

@test "a forced-root-import configuration mutant is rejected diagnostically" {
  mutant=$(jq '.forceImportRoot=true' <<<"$VALID_NAS")
  run assert_nas_configuration_json "$mutant"
  [ "$status" -ne 0 ]
  [[ $output == *"NAS evaluated configuration mismatch"* ]]
  [[ $output == *'"forceImportRoot": true'* ]]
}

@test "an extra approved-key mutant is rejected diagnostically" {
  mutant=$(jq '.authorizedKeys += ["ssh-ed25519 unexpected"]' <<<"$VALID_OPERATOR")
  run assert_operator_configuration_json "$mutant"
  [ "$status" -ne 0 ]
  [[ $output == *"operator evaluated policy mismatch"* ]]
  [[ $output == *'"keyCount":2'* ]]
}

@test "a duplicated concern declaration is rejected diagnostically" {
  mkdir -p "$WORKDIR/hosts"
  cp -R "$ROOT/hosts/nas" "$WORKDIR/hosts/nas"
  printf '\nservices.samba.enable = true;\n' >>"$WORKDIR/hosts/nas/default.nix"
  run assert_host_concern_ownership "$WORKDIR"
  [ "$status" -ne 0 ]
  [[ $output == *"default.nix redeclares the Samba module concern"* ]]
}

@test "a broken ZFS module mutant is rejected diagnostically" {
  mutant=$(jq '.zfsModuleBroken=true' <<<"$VALID_KERNEL")
  run assert_kernel_zfs_projection_json "$mutant"
  [ "$status" -ne 0 ]
  [[ $output == *"kernel/ZFS projection is incompatible"* ]]
  [[ $output == *'"zfsModuleBroken": true'* ]]
}
