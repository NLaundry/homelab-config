## Why

The NAS (`NASty`, 10.10.10.11) is configured with a single `/etc/nixos/configuration.nix` edited imperatively on the box. We want the config to live in this git repo, be pushed remotely from a workstation, and coexist with future hosts — without tying the layout to this one machine's hostname.

## What Changes

- Introduce a **flake** (`flake.nix`) exposing `nixosConfigurations.nas`, tracking `nixpkgs` release `nixos-26.05` (matches the box's `system.stateVersion`).
- Restructure the config into a **host-agnostic directory**: `hosts/nas/` (role name, not `nasty`), split into `default.nix` (system/users/ssh/services) + `zfs.nix` (hostId, pools, ZFS-compatible-kernel selection) + `hardware-configuration.nix` (moved as-is).
- Add a **`Makefile`** that pushes the config to the box via `nixos-rebuild --flake .#nas --target-host` **and** `--build-host` (builds on the NAS, since the workstation is macOS/aarch64 and can't build a Linux system locally).
- **Fold in** two agreed additions on top of the current on-disk config:
  - `users.users.operator` — wheel/admin, SSH key, passwordless sudo.
  - `boot.zfs.forceImportRoot = false` — adopts the safer 26.11 default and silences the eval warning.
- **Remove** the root-level `configuration.nix` and `hardware-configuration.nix` after their content moves under `hosts/nas/`.
- Record the running list of **deferred decisions** (D1–D9) so nothing is silently dropped.

Not breaking: the resulting system is behaviorally equivalent to today's box plus the operator user and the `forceImportRoot` default.

## Capabilities

### New Capabilities
- `nixos-deploy`: Repo-based, flake-driven definition of the NAS host and a repeatable mechanism to push it to the box remotely.

### Modified Capabilities
<!-- None — no existing specs in openspec/specs/. -->

## Impact

- **New files**: `flake.nix`, `flake.lock`, `hosts/nas/default.nix`, `hosts/nas/zfs.nix`, `hosts/nas/hardware-configuration.nix`, `Makefile`.
- **Removed files**: `./configuration.nix`, `./hardware-configuration.nix` (content migrated).
- **Unchanged**: `ansible/` (non-Nix homelab hosts stay on Ansible), `docs/`.
- **External**: adds a `nixpkgs` flake input; requires the box reachable over SSH as root (existing `ansible_homelab` key) for `--target-host`/`--build-host`.
- **Deploy target**: `nixos-rebuild switch --flake .#nas --target-host root@10.10.10.11 --build-host root@10.10.10.11`.
