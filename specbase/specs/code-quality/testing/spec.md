---
id: code-quality.testing
---

### Requirement: Tests exercise the responsible production path
**ID:** `production-path-fidelity`
A repository test SHALL exercise the production artifact or execution path responsible for the requirement it claims to cover rather than reproducing that logic inside a fixture or test double.

#### Scenario: A fixture copies the decision under test
**ID:** `copied-logic-rejected`
- **WHEN** a test obtains its result from logic copied out of the production path
- **THEN** review rejects the test as evidence for that production behavior

### Requirement: Assertions are sensitive to the covered defect
**ID:** `defect-sensitive-assertions`
For every requirement an automated test claims to cover, the test SHALL assert an independently obtained outcome that becomes false when that requirement is violated.

#### Scenario: Expected and actual values share one source
**ID:** `self-fulfilling-oracle-rejected`
- **WHEN** a test derives its expected and observed values from the same source
- **THEN** review rejects the assertion as insensitive to the covered defect

### Requirement: Waiting uses bounded relevant conditions
**ID:** `condition-based-synchronization`
A test that waits or retries SHALL use a finite deadline and a condition that is directly relevant to the operation it subsequently asserts instead of a fixed sleep or unbounded retry.

#### Scenario: A protocol needs startup time
**ID:** `protocol-readiness-waited`
- **WHEN** a test requires a service protocol to become ready
- **THEN** it waits for a bounded protocol-relevant condition rather than elapsed time alone

### Requirement: Mutable test state is run-scoped
**ID:** `run-scoped-state`
A test that creates mutable state SHALL place that state in a collision-resistant namespace owned by the current run.

#### Scenario: Two live runs overlap
**ID:** `concurrent-runs-separated`
- **WHEN** two test runs create fixtures concurrently
- **THEN** each run addresses only its own namespace

### Requirement: Tests are order-independent
**ID:** `order-independent-tests`
A repository test SHALL produce the same verdict regardless of test ordering and SHALL NOT require unexplained residue from an earlier run.

#### Scenario: A test runs by itself
**ID:** `isolated-run-preserves-verdict`
- **WHEN** a test is executed without earlier tests in the suite
- **THEN** it reaches the same verdict from its declared setup

### Requirement: Live cleanup runs after supported failures
**ID:** `failure-safe-live-cleanup`
A live test that creates deployed state SHALL execute its registered cleanup after setup or assertion failures within the runner's supported teardown boundary.

#### Scenario: A live assertion fails after mutation
**ID:** `failed-live-assertion-cleans`
- **WHEN** a live assertion fails after creating a fixture
- **THEN** teardown attempts the registered cleanup

### Requirement: Live cleanup preserves the original failure
**ID:** `live-cleanup-preserves-failure`
A live test cleanup failure SHALL NOT replace an earlier setup or assertion failure.

#### Scenario: Cleanup also fails
**ID:** `cleanup-failure-preserves-assertion`
- **WHEN** an assertion fails and its subsequent cleanup also fails
- **THEN** the test retains the assertion as the original failure

### Requirement: Residual live state fails the test
**ID:** `residual-state-visible`
A live test whose cleanup cannot remove its fixture SHALL fail.

#### Scenario: Cleanup leaves deployed state
**ID:** `cleanup-residue-fails-test`
- **WHEN** cleanup leaves deployed test state behind
- **THEN** the test reports a failed verdict

### Requirement: Residual live state identifies the resource
**ID:** `residual-resource-identified`
A live test whose cleanup leaves deployed state SHALL report the exact remaining run-scoped resource requiring operator action.

#### Scenario: An operator must remove residue
**ID:** `cleanup-failure-reports-resource`
- **WHEN** cleanup cannot remove a run-scoped resource
- **THEN** the failure identifies that exact resource

### Requirement: Failures identify the unestablished outcome
**ID:** `actionable-test-failures`
A repository test failure SHALL identify the governed outcome that was not established.

#### Scenario: A remote assertion returns non-zero
**ID:** `remote-failure-identifies-outcome`
- **WHEN** a remote assertion cannot complete
- **THEN** the failure identifies the intended outcome

### Requirement: Failures preserve observed context
**ID:** `failure-context-preserved`
A repository test failure SHALL preserve the observed context needed to distinguish assertion failure from transport or setup failure.

#### Scenario: A remote command returns non-zero
**ID:** `remote-failure-keeps-context`
- **WHEN** a remote command prevents an assertion from completing
- **THEN** the failure retains the relevant command or transport diagnostic
