#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$ROOT"

fail() { printf 'current-bindings: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"; }
contains() { grep -Fq -- "$2" "$1" || fail "$1 does not contain: $2"; }

flake_exposes_role_attribute() {
  need nix
  contains flake.nix 'nixosConfigurations.nas'
  [[ $(nix eval --raw .#nixosConfigurations.nas.config.system.build.toplevel.drvPath) == /nix/store/* ]] || fail 'nas configuration did not evaluate to a derivation'
}

no_hostname_derived_attribute() {
  need nix; need jq
  local attrs
  attrs=$(nix eval --json .#nixosConfigurations --apply builtins.attrNames)
  jq -e 'index("nas") != null and index("NASty") == null and index("nasty") == null' <<<"$attrs" >/dev/null || fail "unexpected NixOS configuration attributes: $attrs"
}

role_attribute_evaluates() { flake_exposes_role_attribute; }

default_imports_siblings() {
  local module base
  for module in hosts/nas/*.nix; do
    base=${module##*/}
    [[ "$base" == default.nix ]] && continue
    contains hosts/nas/default.nix "./$base"
  done
}

default_imports_role_module() {
  contains hosts/nas/default.nix './zfs.nix'
  ! grep -Eq 'boot\.zfs|boot\.kernelPackages|networking\.hostId' hosts/nas/default.nix || fail 'default.nix redeclares the ZFS module concern'
}

config_intent() {
  need nix; need jq
  local pools filesystems
  pools=$(nix eval --json .#nixosConfigurations.nas.config.boot.zfs.extraPools)
  jq -e 'sort == ["mediaBin","smolBoy"]' <<<"$pools" >/dev/null || fail "unexpected ZFS pools: $pools"
  [[ $(nix eval --raw .#nixosConfigurations.nas.config.networking.hostId) == 007f0200 ]] || fail 'unexpected networking.hostId'
  filesystems=$(nix eval --json .#nixosConfigurations.nas.config.boot.supportedFilesystems)
  jq -e '.zfs == true' <<<"$filesystems" >/dev/null || fail 'ZFS is not a supported filesystem'
  [[ $(nix eval --json .#nixosConfigurations.nas.config.boot.zfs.forceImportRoot) == false ]] || fail 'forceImportRoot is not false'
}

eval_no_force_import_root_warning() {
  need nix
  local out err
  out=$(mktemp); err=$(mktemp)
  trap 'rm -f "$out" "$err"' RETURN
  nix eval --json .#nixosConfigurations.nas.config.boot.zfs.forceImportRoot >"$out" 2>"$err" || { cat "$err" >&2; fail 'forceImportRoot evaluation failed'; }
  [[ $(<"$out") == false ]] || fail 'forceImportRoot is not false'
  ! grep -q 'forceImportRoot' "$err" || { cat "$err" >&2; fail 'forceImportRoot evaluation emitted a warning'; }
  rm -f "$out" "$err"
  trap - RETURN
}

operator_config_intent() {
  need nix; need jq
  nix eval --json .#nixosConfigurations.nas.config.users.users.operator | jq -e '
    .isNormalUser == true and (.extraGroups | index("wheel")) != null and
    (.openssh.authorizedKeys.keys | length) > 0 and
    (.openssh.authorizedKeys.keys | all(startswith("ssh-ed25519 ")))
  ' >/dev/null || fail 'operator user configuration does not conform'
  [[ $(nix eval --json .#nixosConfigurations.nas.config.security.sudo.wheelNeedsPassword) == false ]] || fail 'wheel still requires a sudo password'
}

utility_packages_eval() {
  need nix
  [[ $(nix eval --json .#nixosConfigurations.nas.config.programs.vim.enable) == true ]] || fail 'vim is not enabled'
  [[ $(nix eval --json .#nixosConfigurations.nas.config.programs.git.enable) == true ]] || fail 'git is not enabled'
}

flake_input_pins_release() { contains flake.nix 'nixos-26.05'; }

lock_committed_pinned() {
  need git; need jq
  git ls-files --error-unmatch flake.lock >/dev/null || fail 'flake.lock is not tracked'
  jq -e '.nodes.nixpkgs.locked.rev | type == "string" and length > 0' flake.lock >/dev/null || fail 'flake.lock has no resolved nixpkgs revision'
}

flake_evaluates_against_pin() { need nix; nix flake check; }

run_mode() {
  case "$1" in
    flake-exposes-role-attribute) flake_exposes_role_attribute ;;
    no-hostname-derived-attribute) no_hostname_derived_attribute ;;
    role-attribute-evaluates) role_attribute_evaluates ;;
    default-imports-siblings) default_imports_siblings ;;
    default-imports-role-module) default_imports_role_module ;;
    config-intent) config_intent ;;
    eval-no-force-import-root-warning) eval_no_force_import_root_warning ;;
    operator-config-intent) operator_config_intent ;;
    utility-packages-eval) utility_packages_eval ;;
    flake-input-pins-release) flake_input_pins_release ;;
    lock-committed-pinned) lock_committed_pinned ;;
    flake-evaluates-against-pin) flake_evaluates_against_pin ;;
    *) fail "unknown selector: $1" ;;
  esac
}

case ${1:-} in
  all-local)
    for mode in \
      flake-exposes-role-attribute no-hostname-derived-attribute role-attribute-evaluates \
      default-imports-siblings default-imports-role-module config-intent \
      eval-no-force-import-root-warning operator-config-intent utility-packages-eval \
      flake-input-pins-release lock-committed-pinned flake-evaluates-against-pin; do
      printf 'binding %s... ' "$mode"
      run_mode "$mode"
      printf 'ok\n'
    done
    ;;
  '') fail 'usage: current-bindings.sh {all-local|binding-selector}' ;;
  *) run_mode "$1" ;;
esac
