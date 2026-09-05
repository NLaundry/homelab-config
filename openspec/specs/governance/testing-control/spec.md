---
id: governance.testing-control
---

## Purpose

The repository's test-control surface keeps routine checks reproducible, integration subjects isolated, live verification explicit, and platform-specific builders selectable without accidental activation or network access.

## Requirements

### Requirement: Integration subjects remain ephemeral
**ID:** `test-subject-boundary`
Every registered integration-test subject SHALL run as an ephemeral guest or disposable test environment and SHALL NOT activate its candidate configuration on the builder.

#### Scenario: Registered integration subject runs
**ID:** `integration-subject-is-disposable`
- **WHEN** a registered integration test executes
- **THEN** the candidate runs in a disposable environment and the builder retains its original active system

### Requirement: Ordinary test guests remain network-isolated
**ID:** `test-network-boundary`
Every ordinary integration-test guest SHALL use only explicitly declared private test networks and SHALL have no implicit interface, default route, or route to the physical LAN.

#### Scenario: Guest routes are inspected
**ID:** `guest-has-only-declared-routes`
- **WHEN** an ordinary integration guest boots
- **THEN** its interfaces and routes contain only the declared private topology and cannot reach the physical LAN

### Requirement: Lint remains static and fail-fast
**ID:** `lint-stage`
The lint stage SHALL run strict spec conformance and flake evaluation without starting VM or live-estate checks and SHALL stop on the first failed phase.

#### Scenario: Static conformance fails
**ID:** `lint-failure-stops-stage`
- **WHEN** strict spec conformance or flake evaluation fails
- **THEN** lint returns failure without running a later VM or live phase

### Requirement: Routine tests exclude live and platform-specific integration work
**ID:** `test-stage`
The routine test stage SHALL run its registered non-live checks while excluding live-estate verification and the explicitly selected KVM integration aggregate.

#### Scenario: Routine tests run
**ID:** `routine-tests-stay-non-live`
- **WHEN** the default test stage executes
- **THEN** it runs registered routine checks without contacting the live estate or selecting the KVM aggregate

### Requirement: KVM integration builder is explicitly selectable
**ID:** `test-builder-selection`
The test-control interface SHALL expose the fixed KVM integration aggregate and SHALL allow its Linux/KVM-capable store to be selected explicitly without changing the aggregate's derivation identity.

#### Scenario: Alternate KVM store is selected
**ID:** `kvm-store-is-overridden`
- **WHEN** an operator selects an alternate Linux/KVM-capable store
- **THEN** the same fixed integration aggregate executes through that store

### Requirement: Live verification remains independent and non-activating
**ID:** `verify-stage`
The live verification stage SHALL run only registered bounded probes against the current estate, SHALL NOT activate a candidate system, and SHALL propagate each unestablished outcome as failure.

#### Scenario: Live probe fails
**ID:** `live-probe-failure-propagates`
- **WHEN** a registered live probe cannot establish its outcome
- **THEN** verification returns failure, identifies the outcome, and performs no candidate activation
