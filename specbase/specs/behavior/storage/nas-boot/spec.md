---
id: behavior.storage.nas-boot
---

## Purpose
This pair governs the NAS boot contract for importing its existing ZFS data pools with a compatible kernel and an explicit safe root-import policy.

### Requirement: NAS boots with its ZFS data pools imported
**ID:** `pools-import-on-boot`
The NAS configuration SHALL import the `smolBoy` and `mediaBin` ZFS pools via
`boot.zfs.extraPools` on boot, set `networking.hostId` to `007f0200`, and select
a ZFS-compatible kernel package. The pools already exist on disk and SHALL be
imported only, never created by this configuration.

#### Scenario: Pools are declared for boot import
**ID:** `pools-declared`
- **WHEN** the `nas` configuration is evaluated
- **THEN** `boot.zfs.extraPools` contains `smolBoy` and `mediaBin`
- **AND** `networking.hostId` is `007f0200`
- **AND** `boot.supportedFilesystems` contains `zfs`

#### Scenario: A ZFS-compatible kernel is selected
**ID:** `zfs-kernel-selected`
- **WHEN** the `nas` configuration is evaluated
- **THEN** `boot.kernelPackages` resolves to a kernel whose ZFS module is not
  broken
- **AND** the selection is automatic (no manual kernel pin)

#### Scenario: Pools import on boot
**ID:** `pools-import-on-boot-runtime`
- **WHEN** the system boots
- **THEN** pools `smolBoy` and `mediaBin` are imported without `-f`
- **AND** `zpool status` reports both ONLINE

### Requirement: forceImportRoot is false with no eval warning
**ID:** `force-import-root-clean`
The NAS configuration SHALL set `boot.zfs.forceImportRoot = false`, and the
configuration SHALL evaluate without emitting a warning about the
`forceImportRoot` default value.

#### Scenario: forceImportRoot is false and clean
**ID:** `force-import-root-false-clean`
- **WHEN** the `nas` configuration is evaluated
- **THEN** `boot.zfs.forceImportRoot` is `false`
- **AND** no evaluation warning about `forceImportRoot` is emitted
