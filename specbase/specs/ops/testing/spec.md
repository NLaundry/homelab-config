---
id: ops.testing
---

### Requirement: Repository validation uses the lint operation
**ID:** `lint-stage`
The repository SHALL define a `lint` operation that strictly validates current governed specifications and evaluates the Nix flake without starting a test VM or addressing a deployed homelab service. A failure in either validation step SHALL make the operation fail.

#### Scenario: An operator validates current repository truth
**ID:** `lint-validates-repository`
- **WHEN** an operator runs the `lint` operation
- **THEN** strict current-spec validation and flake evaluation run
- **AND** any failure stops the operation before isolated or live testing

### Requirement: Non-live checks use the test operation
**ID:** `test-stage`
The repository SHALL define a `test` operation that executes every phase in an explicit non-live test registry, including the aggregate x86_64-linux NixOS VM test derivation, and returns a non-zero status when any phase fails.

#### Scenario: The complete non-live suite is selected
**ID:** `non-live-suite-executed`
- **WHEN** an operator runs the `test` operation
- **THEN** every registered non-live phase executes
- **AND** each phase completes before the operation succeeds

#### Scenario: A non-live phase fails
**ID:** `non-live-phase-failure-propagates`
- **WHEN** any registered non-live phase reports failure
- **THEN** the `test` operation fails

### Requirement: The remote test store is selectable
**ID:** `test-builder-selection`
The `test` operation SHALL default to a remote Linux store that provides `x86_64-linux`, `kvm`, and `nixos-test`, and SHALL accept a store override without changing the selected test derivation.

#### Scenario: The physical NAS supplies initial test compute
**ID:** `test-runs-on-builder`
- **WHEN** an operator runs the `test` operation with the default store
- **THEN** the physical NAS executes the x86_64-linux derivation with KVM

#### Scenario: The remote store is replaced
**ID:** `test-builder-overridden`
- **WHEN** an operator supplies another compatible Linux/KVM store
- **THEN** the same test derivation is selected through that store

### Requirement: Deployed checks use the verify operation
**ID:** `verify-stage`
The repository SHALL define an independently runnable `verify` operation that invokes the repository's Bats live-verification entry point without activating a system and returns a non-zero status when any selected live check fails.

#### Scenario: An operator checks the current deployment
**ID:** `verify-runs-independently`
- **WHEN** an operator runs the `verify` operation directly
- **THEN** the selected live checks run against the current deployment
- **AND** no deployment activation occurs

#### Scenario: A deployed check fails
**ID:** `verify-propagates-failure`
- **WHEN** a selected Bats check reports that deployed behavior does not hold
- **THEN** the `verify` operation fails and identifies the failed check
