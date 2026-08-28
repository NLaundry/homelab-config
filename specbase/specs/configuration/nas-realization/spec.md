---
id: configuration.nas-realization
---

## Purpose

The NAS realization records the selected declarative settings that make its storage and administrator-access roles reproducible without copying incidental Nix implementation detail into permanent truth.

### Requirement: Storage pools are selected for declarative import
**ID:** `zfs-pool-import-configuration`
The evaluated NAS configuration SHALL declare `mediaBin` and `smolBoy` as the selected pre-existing ZFS pools to import.

#### Scenario: Evaluated pool selection is inspected
**ID:** `selected-pools-match`
- **WHEN** the merged NAS configuration is evaluated
- **THEN** the selected extra-pool set contains exactly `mediaBin` and `smolBoy`

### Requirement: ZFS host identity is stable
**ID:** `zfs-host-identity-stable`
The evaluated NAS configuration SHALL declare the stable host identity required to import its existing ZFS pools safely.

#### Scenario: Host identity is evaluated
**ID:** `stable-host-id-present`
- **WHEN** the merged NAS configuration is evaluated
- **THEN** it contains the selected non-empty ZFS host identity

### Requirement: The selected kernel supports the selected ZFS realization
**ID:** `zfs-kernel-compatible`
The NAS system closure SHALL resolve a kernel and ZFS module combination that builds together from the pinned package set.

#### Scenario: NAS closure is built
**ID:** `kernel-zfs-closure-builds`
- **WHEN** the NAS system closure is built from the pinned inputs
- **THEN** kernel and ZFS module resolution completes without an incompatible or broken selection

### Requirement: Forced root-pool import is disabled
**ID:** `force-import-root-disabled`
The evaluated NAS configuration SHALL disable forced root-pool import.

#### Scenario: Root import policy is evaluated
**ID:** `force-import-root-is-false`
- **WHEN** the merged NAS configuration is evaluated
- **THEN** forced root-pool import is false

### Requirement: Administrator account policy is declarative
**ID:** `operator-account-configuration`
The evaluated NAS configuration SHALL define the selected operator account, approved-key authentication material, administrator-group membership, and non-interactive elevation policy.

#### Scenario: Operator policy is evaluated
**ID:** `operator-policy-present`
- **WHEN** the merged NAS account and privilege configuration is inspected
- **THEN** the selected operator identity, approved key policy, administrator membership, and elevation policy are all present
