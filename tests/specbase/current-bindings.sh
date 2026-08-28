#!/usr/bin/env bash
# shellcheck disable=SC2016
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$ROOT"

fail() {
	printf 'current-bindings: %s\n' "$*" >&2
	exit 1
}
need() { command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"; }
contains() { grep -Fq -- "$2" "$1" || fail "$1 does not contain: $2"; }
observe() { printf 'observation %s=%s\n' "$1" "$2"; }

nix_eval_json() {
	nix eval --no-update-lock-file --json "$@"
}

assert_nas_configuration_json() {
	local observed=$1
	jq -e '
    (.pools | sort) == ["mediaBin", "smolBoy"] and
    .hostId == "007f0200" and
    .forceImportRoot == false and
    .zfsSupported == true and
    .stateVersion == "26.05" and
    .targetSystem == "x86_64-linux"
  ' <<<"$observed" >/dev/null || {
		printf 'NAS evaluated configuration mismatch: %s\n' "$observed" >&2
		return 1
	}
}

assert_operator_configuration_json() {
	local observed=$1
	jq -e '
    .isNormalUser == true and
    (.extraGroups | index("wheel")) != null and
    (.authorizedKeys | length) == 1 and
    (.authorizedKeys[0] | startswith("ssh-ed25519 ")) and
    .wheelNeedsPassword == false
  ' <<<"$observed" >/dev/null || {
		printf 'operator evaluated policy mismatch: %s\n' "$(jq -c '{isNormalUser,extraGroups,keyCount:(.authorizedKeys|length),wheelNeedsPassword}' <<<"$observed")" >&2
		return 1
	}
}

assert_kernel_zfs_projection_json() {
	local observed=$1
	jq -e '
    .targetSystem == "x86_64-linux" and
    (.kernelVersion | type == "string" and length > 0) and
    (.kernelDrvPath | startswith("/nix/store/") and endswith(".drv")) and
    (.zfsModuleAttribute | type == "string" and length > 0) and
    (.zfsModuleDrvPath | startswith("/nix/store/") and endswith(".drv")) and
    .zfsModuleBroken == false and
    (.toplevelDrvPath | startswith("/nix/store/") and endswith(".drv"))
  ' <<<"$observed" >/dev/null || {
		printf 'kernel/ZFS projection is incompatible: %s\n' "$observed" >&2
		return 1
	}
}

flake_output_shape() {
	need nix
	need jq
	local observed
	observed=$(nix eval --no-update-lock-file --json \
		--apply 'configs: builtins.mapAttrs (role: host: {
      hostName = host.config.networking.hostName;
      targetSystem = host.config.system.build.toplevel.system;
      toplevelDrvPath = host.config.system.build.toplevel.drvPath;
    }) configs' .#nixosConfigurations)
	jq -e '
    (.nas | type == "object") and
    (.nas.hostName | type == "string" and length > 0) and
    (.nas.hostName != "nas") and
    (.nas.targetSystem == "x86_64-linux") and
    (.nas.toplevelDrvPath | startswith("/nix/store/") and endswith(".drv"))
  ' <<<"$observed" >/dev/null || fail "role-oriented host output is invalid: $observed"
	observe managed-hosts "$(jq -c -S . <<<"$observed")"
}

host_module_layout() {
	local module base
	for module in hosts/nas/*.nix; do
		base=${module##*/}
		[[ "$base" == default.nix ]] && continue
		contains hosts/nas/default.nix "./$base"
	done
	observe host-module-siblings "$(find hosts/nas -maxdepth 1 -name '*.nix' -print | LC_ALL=C sort | tr '\n' ',')"
}

assert_host_concern_ownership() {
	local root=${1:-.} default
	default="$root/hosts/nas/default.nix"
	contains "$root/hosts/nas/zfs.nix" 'boot.zfs.extraPools'
	contains "$root/hosts/nas/samba.nix" 'services.samba'
	contains "$root/hosts/nas/avahi.nix" 'services.avahi'
	contains "$root/hosts/nas/hardware-configuration.nix" 'nixpkgs.hostPlatform'
	! grep -Eq 'boot\.zfs|boot\.kernelPackages|networking\.hostId' "$default" ||
		fail 'default.nix redeclares the ZFS module concern'
	! grep -Eq 'services\.samba' "$default" || fail 'default.nix redeclares the Samba module concern'
	! grep -Eq 'services\.avahi' "$default" || fail 'default.nix redeclares the Avahi module concern'
	! grep -Eq 'fileSystems\.|swapDevices|nixpkgs\.hostPlatform' "$default" ||
		fail 'default.nix redeclares the hardware module concern'
}

host_concern_ownership() {
	assert_host_concern_ownership .
	observe host-concern-owners 'zfs=zfs.nix,samba=samba.nix,avahi=avahi.nix,hardware=hardware-configuration.nix'
}

nas_configuration() {
	need nix
	need jq
	local observed
	observed=$(nix eval --no-update-lock-file --json \
		--apply 'host: {
      pools = host.config.boot.zfs.extraPools;
      hostId = host.config.networking.hostId;
      forceImportRoot = host.config.boot.zfs.forceImportRoot;
      zfsSupported = host.config.boot.supportedFilesystems.zfs;
      stateVersion = host.config.system.stateVersion;
      targetSystem = host.config.system.build.toplevel.system;
    }' .#nixosConfigurations.nas)
	assert_nas_configuration_json "$observed" || fail 'NAS evaluated configuration did not establish the selected policy'
	observe nas-configuration "$(jq -c -S . <<<"$observed")"
}

operator_configuration() {
	need nix
	need jq
	need sha256sum
	local observed expected_digest actual_digest key
	observed=$(nix eval --no-update-lock-file --json \
		--apply 'host: let operator = host.config.users.users.operator; in {
      isNormalUser = operator.isNormalUser;
      extraGroups = operator.extraGroups;
      authorizedKeys = operator.openssh.authorizedKeys.keys;
      wheelNeedsPassword = host.config.security.sudo.wheelNeedsPassword;
    }' .#nixosConfigurations.nas)
	assert_operator_configuration_json "$observed" || fail 'operator evaluated configuration did not establish the selected policy'
	expected_digest=$(tr -d '[:space:]' <tests/specbase/policy/operator-authorized-key.sha256)
	key=$(jq -r '.authorizedKeys[0]' <<<"$observed")
	actual_digest=$(printf '%s' "$key" | sha256sum | awk '{print $1}')
	[[ $actual_digest == "$expected_digest" ]] || fail "operator approved-key digest mismatch: expected $expected_digest, observed $actual_digest"
	observe operator-policy "$(jq -c -S '{isNormalUser,extraGroups,keyCount:(.authorizedKeys|length),wheelNeedsPassword}' <<<"$observed")"
	observe operator-key-digest "$actual_digest"
}

kernel_zfs_projection() {
	need nix
	need jq
	local observed
	observed=$(nix eval --no-update-lock-file --json \
		--apply 'host: let
      zfsAttr = host.config.boot.zfs.package.kernelModuleAttribute;
      zfsModule = host.config.boot.kernelPackages.${zfsAttr};
    in {
      kernelVersion = host.config.boot.kernelPackages.kernel.version;
      kernelDrvPath = host.config.boot.kernelPackages.kernel.drvPath;
      zfsModuleAttribute = zfsAttr;
      zfsModuleDrvPath = zfsModule.drvPath;
      zfsModuleBroken = zfsModule.meta.broken or false;
      toplevelDrvPath = host.config.system.build.toplevel.drvPath;
      targetSystem = host.config.system.build.toplevel.system;
    }' .#nixosConfigurations.nas)
	assert_kernel_zfs_projection_json "$observed" || fail 'kernel/ZFS projection did not establish compatible derivations'
	observe kernel-zfs "$(jq -c -S . <<<"$observed")"
}

lock_resolution() {
	need git
	need jq
	need nix
	local metadata expected observed state_version release_ref
	git ls-files --error-unmatch flake.lock >/dev/null || fail 'flake.lock is not tracked'
	metadata=$(nix flake metadata --no-update-lock-file --json .)
	expected=$(jq -c -S '.nodes.nixpkgs' flake.lock)
	observed=$(jq -c -S '.locks.nodes.nixpkgs' <<<"$metadata")
	[[ $observed == "$expected" ]] || fail "resolved nixpkgs metadata differs from flake.lock: expected $expected, observed $observed"
	jq -e '.locked.rev | type == "string" and length == 40' <<<"$expected" >/dev/null || fail 'flake.lock has no resolved nixpkgs revision'
	state_version=$(nix eval --no-update-lock-file --raw .#nixosConfigurations.nas.config.system.stateVersion)
	release_ref=$(jq -r '.original.ref // ""' <<<"$expected")
	[[ $release_ref == "nixos-$state_version" ]] || fail "nixpkgs release/stateVersion mismatch: release=$release_ref stateVersion=$state_version"
	observe nixpkgs-lock "$(jq -c -S '{original,locked:{rev:.locked.rev,narHash:.locked.narHash}}' <<<"$expected")"
	observe state-version "$state_version"
}

flake_evaluates_against_lock() {
	need nix
	nix flake check --no-update-lock-file --all-systems --no-build
	observe flake-check no-build-success
}

managed_host_closure() {
	need nix
	local current_system target_system output
	current_system=$(nix eval --impure --raw --expr builtins.currentSystem)
	target_system=$(nix eval --no-update-lock-file --raw .#nixosConfigurations.nas.config.system.build.toplevel.system)
	args=(build --no-update-lock-file --no-link --print-out-paths)
	if [[ $current_system != "$target_system" ]]; then
		[[ -n ${TEST_STORE:-} ]] || fail "managed host closure targets $target_system; set TEST_STORE to a compatible trusted store"
		args+=(--store "$TEST_STORE" --eval-store auto)
	fi
	output=$(nix "${args[@]}" .#nixosConfigurations.nas.config.system.build.toplevel)
	[[ $output == /nix/store/* ]] || fail "managed host closure build returned an invalid output: $output"
	observe closure-output "$output"
	observe closure-builder "${TEST_STORE:-local:$current_system}"
}

run_mode() {
	case "$1" in
	flake-output-shape) flake_output_shape ;;
	host-module-layout) host_module_layout ;;
	host-concern-ownership) host_concern_ownership ;;
	nas-configuration) nas_configuration ;;
	operator-configuration) operator_configuration ;;
	kernel-zfs-projection) kernel_zfs_projection ;;
	lock-resolution) lock_resolution ;;
	flake-evaluates-against-lock) flake_evaluates_against_lock ;;
	managed-host-closure) managed_host_closure ;;
	*) fail "unknown selector: $1" ;;
	esac
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
	case ${1:-} in
	all-local)
		for mode in \
			flake-output-shape host-module-layout host-concern-ownership \
			nas-configuration operator-configuration kernel-zfs-projection \
			lock-resolution flake-evaluates-against-lock managed-host-closure; do
			printf 'binding %s...\n' "$mode"
			run_mode "$mode"
			printf 'binding %s ok\n' "$mode"
		done
		;;
	'') fail 'usage: current-bindings.sh {all-local|binding-selector}' ;;
	*) run_mode "$1" ;;
	esac
fi
