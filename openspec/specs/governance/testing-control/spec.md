---
id: governance.testing-control
---

## Purpose

Keep configuration checks, isolated VM tests, and live probes separate so operators know what each command does.

## Requirements

### Requirement: Integration subjects remain temporary
**ID:** `test-subject-boundary`
An integration test SHALL run its candidate in a disposable environment and SHALL NOT activate that candidate on its builder.

#### Scenario: Integration test runs
**ID:** `integration-subject-is-disposable`
- **WHEN** an integration test executes
- **THEN** the candidate runs in a disposable environment and the builder keeps its active system

### Requirement: Ordinary test guests remain network-isolated
**ID:** `test-network-boundary`
An ordinary test guest SHALL use only its declared private test networks and SHALL have no default route or access to the physical LAN.

#### Scenario: Guest routes are inspected
**ID:** `guest-has-only-declared-routes`
- **WHEN** an ordinary test guest boots
- **THEN** its interfaces and routes contain only the declared private network and cannot reach the physical LAN

### Requirement: Configuration checks do not build or deploy
**ID:** `check-stage`
`make check` SHALL evaluate the Nix configuration without building guests, activating hosts, or running live probes.

#### Scenario: Configuration evaluation fails
**ID:** `check-failure-stops-stage`
- **WHEN** Nix evaluation fails
- **THEN** the command returns failure without starting a VM or live phase

### Requirement: The VM builder is selectable
**ID:** `test-builder-selection`
`make test-vm` SHALL allow an operator to select a Linux builder with KVM through `TEST_STORE` without changing the test definition.

#### Scenario: Alternate VM builder is selected
**ID:** `kvm-store-is-overridden`
- **WHEN** an operator selects another suitable build store
- **THEN** the same Samba VM test runs through that store

### Requirement: Live verification remains independent and non-activating
**ID:** `verify-stage`
`make verify` SHALL run bounded probes against the current hosts, SHALL NOT activate a candidate, and SHALL fail when a selected outcome cannot be established.

#### Scenario: Live probe fails
**ID:** `live-probe-failure-propagates`
- **WHEN** a selected live probe cannot establish its outcome
- **THEN** verification returns failure, identifies the outcome, and performs no activation
