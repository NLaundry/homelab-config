---
id: code-quality.testing
---

## Purpose

Repository tests protect selected homelab behavior and critical invariants without becoming a second product or unsafe live workload.

## MODIFIED Requirements

### Requirement: Tests protect selected behavior or critical invariants
**ID:** `production-path-fidelity`
A repository test SHALL exercise a user-visible behavior or a critical operational or structural invariant through the responsible production path. A test-only production subsystem SHALL NOT be introduced unless that subsystem is itself a selected durable capability.

#### Scenario: A test protects only its own machinery
**ID:** `copied-logic-rejected`
- **WHEN** deleting both a subsystem and its tests would change no selected homelab behavior or critical invariant
- **THEN** review rejects that subsystem as unnecessary verification machinery

### Requirement: Mutable live state is uniquely scoped
**ID:** `run-scoped-state`
A live check that mutates deployed state SHALL create only a collision-resistant verifier-owned namespace and SHALL address no state outside that exact namespace during cleanup.

#### Scenario: Two live runs overlap
**ID:** `concurrent-runs-separated`
- **WHEN** two live runs create fixtures concurrently
- **THEN** each run creates and cleans only its own unique namespace

### Requirement: Live cleanup runs after supported failures
**ID:** `failure-safe-live-cleanup`
A live check that creates deployed state SHALL register cleanup after acquiring the resource and SHALL attempt exact cleanup after setup, assertion, interruption, or normal completion within the runner's supported boundary.

#### Scenario: A live assertion fails after mutation
**ID:** `failed-live-assertion-cleans`
- **WHEN** a live assertion fails after creating a fixture
- **THEN** cleanup attempts to remove the exact fixture and reports residue as failure

### Requirement: Failures identify the unestablished outcome
**ID:** `actionable-test-failures`
A repository check failure SHALL identify the user-visible behavior or critical invariant that was not established and retain the directly relevant observed diagnostic.

#### Scenario: A remote behavior check cannot complete
**ID:** `remote-failure-identifies-outcome`
- **WHEN** transport, setup, or assertion failure prevents a remote outcome from being established
- **THEN** the failure names that outcome and preserves the relevant observation

## REMOVED Requirements

### Requirement: Assertions are sensitive to the covered defect
**ID:** `defect-sensitive-assertions`
**Reason:** The rule encouraged a controlled negative fixture for each assertion rather than higher-leverage behavior evidence.
**Migration:** Semantic evidence remains part of production-path review.

### Requirement: Waiting uses bounded relevant conditions
**ID:** `condition-based-synchronization`
**Reason:** This implementation-level checklist does not require a separate durable requirement.
**Migration:** Review blocking or unbounded waits as ordinary code quality.

### Requirement: Tests are order-independent
**ID:** `order-independent-tests`
**Reason:** Unique state and responsible setup cover the selected live risk without a separate normative rule.
**Migration:** Treat unexplained cross-test state as an ordinary defect.

### Requirement: Live cleanup preserves the original failure
**ID:** `live-cleanup-preserves-failure`
**Reason:** Failure precedence does not need a separate governed requirement.
**Migration:** The responsible live check should report both the missing outcome and cleanup residue.

### Requirement: Residual live state fails the test
**ID:** `residual-state-visible`
**Reason:** This is incorporated into `failure-safe-live-cleanup`.
**Migration:** Cleanup residue remains a failing outcome under the retained requirement.

### Requirement: Residual live state identifies the resource
**ID:** `residual-resource-identified`
**Reason:** Exact state scope and actionable failures already require useful identification.
**Migration:** Retained requirements govern exact namespaces and diagnostics.

### Requirement: Failures preserve observed context
**ID:** `failure-context-preserved`
**Reason:** This is incorporated into `actionable-test-failures`.
**Migration:** Relevant observed context remains required by the retained requirement.
