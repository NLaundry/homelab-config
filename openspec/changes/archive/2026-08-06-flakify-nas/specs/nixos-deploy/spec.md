## ADDED Requirements

### Requirement: Flake defines the NAS host

The repository SHALL contain a `flake.nix` that exposes `nixosConfigurations.nas` built from `nixpkgs` release `nixos-26.05`. The configuration attribute name MUST be host-agnostic (`nas`), independent of the machine's hostname.

#### Scenario: Flake evaluates the NAS configuration

- **WHEN** `nix flake check` (or `nixos-rebuild ... --flake .#nas build`) is run at the repo root
- **THEN** the `nas` configuration evaluates without error
- **AND** the evaluated system's `networking.hostName` is `NASty`

#### Scenario: Attribute name is not tied to the hostname

- **WHEN** inspecting the flake outputs
- **THEN** the configuration is addressable as `.#nas`
- **AND** no directory or flake attribute is named after the `NASty` hostname

### Requirement: Host config is modular and host-agnostic in layout

The NAS configuration SHALL live under `hosts/nas/`, split into `default.nix` (system, users, SSH, services), `zfs.nix` (ZFS settings and kernel selection), and `hardware-configuration.nix` (hardware scan, moved unchanged). `default.nix` MUST import the other two modules.

#### Scenario: Modules compose

- **WHEN** the `nas` configuration is evaluated
- **THEN** `hosts/nas/default.nix` imports `./zfs.nix` and `./hardware-configuration.nix`
- **AND** the ZFS pool import, hostId, and kernel selection come from `zfs.nix`

### Requirement: Configuration preserves current system behavior plus agreed additions

The migrated configuration SHALL be behaviorally equivalent to the current on-disk `configuration.nix`, and additionally SHALL define an `operator` admin user and set `boot.zfs.forceImportRoot = false`.

#### Scenario: ZFS pools import declaratively

- **WHEN** the system boots
- **THEN** pools `smolBoy` and `mediaBin` are imported via `boot.zfs.extraPools`
- **AND** `networking.hostId` is `007f0200`
- **AND** the kernel is the latest ZFS-compatible package (no manual pin)

#### Scenario: Operator user can administer over SSH without a password

- **WHEN** the config is applied
- **THEN** user `operator` exists in the `wheel` group with the provided SSH public key authorized
- **AND** `operator` can run `sudo` without being prompted for a password

#### Scenario: forceImportRoot warning is resolved

- **WHEN** the configuration is evaluated
- **THEN** `boot.zfs.forceImportRoot` is `false`
- **AND** no eval warning about its default value is emitted

### Requirement: Config is pushed remotely via a Makefile

The repository SHALL provide a `Makefile` whose default deploy target pushes the flake to the box using `nixos-rebuild --flake .#nas --target-host` with `--build-host` pointed at the NAS, so the Linux system is built on the NAS rather than the (macOS) workstation.

#### Scenario: Deploy from workstation

- **WHEN** `make deploy` is run from the repo root on the macOS workstation
- **THEN** `nixos-rebuild switch` is invoked with `--flake .#nas`, `--target-host root@10.10.10.11`, and `--build-host root@10.10.10.11`
- **AND** the build occurs on the NAS, not locally

#### Scenario: Safe activation variants exist

- **WHEN** the operator wants to stage without activating, or activate without persisting to the bootloader
- **THEN** the Makefile provides `boot` (activate next boot) and `test` (activate now, revert on reboot) targets in addition to `deploy`
