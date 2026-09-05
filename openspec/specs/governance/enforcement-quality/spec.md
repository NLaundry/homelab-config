---
id: governance.enforcement-quality
---

## Purpose

Checks protect useful behavior, report clear failures, and leave live data safe.

## Requirements

### Requirement: Checks exercise the responsible code
**ID:** `production-path-fidelity`
A check SHALL exercise the code responsible for the claimed behavior rather than a copied implementation or documentation text.

#### Scenario: A check is proposed
**ID:** `copied-logic-rejected`
- **WHEN** a check is added or changed
- **THEN** it protects useful behavior or a concrete failure risk without adding machinery solely to test that machinery

### Requirement: Mutable live state is uniquely scoped
**ID:** `run-scoped-state`
A live check that writes data SHALL use a unique verifier-owned location and SHALL clean up only data it created there.

#### Scenario: Live runs overlap
**ID:** `concurrent-runs-separated`
- **WHEN** two live checks create test data concurrently
- **THEN** each run creates and removes only its own data

### Requirement: Live cleanup is failure-safe
**ID:** `failure-safe-live-cleanup`
A live check SHALL arrange cleanup when it acquires a resource, attempt cleanup after failure or interruption, and report any cleanup failure.

#### Scenario: Assertion fails after mutation
**ID:** `failed-live-assertion-cleans`
- **WHEN** a live assertion fails after creating test data
- **THEN** cleanup targets only that data and any remaining data makes the check fail

### Requirement: Failures explain what could not be checked
**ID:** `actionable-test-failures`
A failed check SHALL identify the failed operation and retain the relevant error or expected and observed result without revealing secrets.

#### Scenario: Remote check cannot complete
**ID:** `remote-failure-identifies-outcome`
- **WHEN** a connection, command, assertion, or cleanup fails
- **THEN** the result identifies that stage and its relevant error

### Requirement: Results state their limits
**ID:** `assertion-scoped-evidence`
A result SHALL claim only outcomes established by its observations.

#### Scenario: A limited check passes
**ID:** `broad-binding-is-rejected`
- **WHEN** a VM behavior check or live health check passes
- **THEN** the report does not claim untested physical storage, full deployment correctness, or completed recovery drills
