---
id: ops.testing
---

## Purpose

Repository testing keeps fast static checks, focused deterministic tests, optional VM integration, and live deployed behavior distinct.

## MODIFIED Requirements

### Requirement: Fast non-live checks use the test operation
**ID:** `test-stage`
The repository SHALL define a `test` operation that runs the declared fast non-live repository checks without addressing a deployed service or selecting the optional VM derivation. Any selected phase failure SHALL make the operation fail.

#### Scenario: An operator runs routine repository tests
**ID:** `non-live-suite-executed`
- **WHEN** an operator runs `make test`
- **THEN** the declared fast non-live phases execute without VM or live service access

#### Scenario: A fast non-live phase fails
**ID:** `non-live-phase-failure-propagates`
- **WHEN** any selected phase reports failure
- **THEN** the `test` operation fails

### Requirement: VM integration uses an explicit optional operation
**ID:** `test-builder-selection`
The repository SHALL define an explicit `test-vm` operation that selects the fixed aggregate x86_64-linux NixOS VM derivation through an overridable compatible Linux/KVM store. Routine `make test` SHALL NOT invoke this operation implicitly.

#### Scenario: The physical NAS supplies optional VM compute
**ID:** `test-runs-on-builder`
- **WHEN** an operator runs `make test-vm` with the default store
- **THEN** the physical NAS executes the fixed aggregate derivation with KVM

#### Scenario: The VM execution store is replaced
**ID:** `test-builder-overridden`
- **WHEN** an operator supplies another compatible Linux/KVM store
- **THEN** the same aggregate derivation is selected through that store

### Requirement: Deployed behavior uses the verify operation
**ID:** `verify-stage`
The repository SHALL define an independently runnable `verify` operation that selects only default user/operator-facing live checks, performs no activation, and returns non-zero when any selected behavior does not hold.

#### Scenario: An operator checks the current deployment
**ID:** `verify-runs-independently`
- **WHEN** an operator runs `make verify`
- **THEN** default deployed behavior checks run against the current NAS without activation or test-only safety profiles

#### Scenario: A deployed behavior check fails
**ID:** `verify-propagates-failure`
- **WHEN** a selected live check reports that deployed behavior does not hold
- **THEN** `make verify` fails and identifies the missing outcome
