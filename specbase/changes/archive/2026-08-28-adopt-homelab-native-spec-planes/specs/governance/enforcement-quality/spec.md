---
id: governance.enforcement-quality
---

## Purpose

Repository evidence establishes durable claims through scoped, sensitive, diagnostic, and safely operated checks without converting helper existence or wrapper success into false confidence.

## MODIFIED Requirements

### Requirement: Evidence follows the responsible production path
**ID:** `production-path-fidelity`
A repository check SHALL exercise the claimed outcome or invariant through the responsible production path and SHALL NOT introduce a test-only production subsystem unless that subsystem is itself selected durable truth.

#### Scenario: Test protects only its own machinery
**ID:** `copied-logic-rejected`
- **WHEN** removing both a verification subsystem and its tests would change no selected homelab outcome or critical invariant
- **THEN** enforcement-quality review rejects the subsystem as unnecessary machinery

### Requirement: Mutable live state is uniquely scoped
**ID:** `run-scoped-state`
A live check that mutates deployed state SHALL create only a collision-resistant verifier-owned namespace and SHALL address no state outside that exact namespace during cleanup.

#### Scenario: Live runs overlap
**ID:** `concurrent-runs-separated`
- **WHEN** two live checks create fixtures concurrently
- **THEN** each run creates and cleans only its own unique namespace

### Requirement: Live cleanup is failure-safe
**ID:** `failure-safe-live-cleanup`
A live check that creates deployed state SHALL register exact cleanup after acquisition, attempt it after every runner-supported completion path, and report residue as failure.

#### Scenario: Assertion fails after mutation
**ID:** `failed-live-assertion-cleans`
- **WHEN** a live assertion fails after acquiring a fixture
- **THEN** cleanup targets the exact fixture and any remaining residue fails the check

### Requirement: Failures identify the unestablished truth
**ID:** `actionable-test-failures`
A repository check failure SHALL identify the requirement outcome or invariant that was not established and retain the directly relevant expected and observed diagnostic.

#### Scenario: Remote check cannot complete
**ID:** `remote-failure-identifies-outcome`
- **WHEN** transport, setup, assertion, or cleanup prevents a remote outcome from being established
- **THEN** the failure names the outcome and preserves the diagnostic that distinguishes the failure stage

### Requirement: Bindings are assertion-scoped
**ID:** `assertion-scoped-evidence`
An enforcement binding SHALL cover only requirements directly established by its named observations and SHALL NOT treat shared setup, helper existence, wrapper invocation, or whole-suite success as independent evidence.

#### Scenario: Broad suite is bound to unrelated claims
**ID:** `broad-binding-is-rejected`
- **WHEN** one source exit status is used to cover requirements for which it emits no direct observation
- **THEN** enforcement conformance or review rejects or narrows the binding

### Requirement: Evidence records retain integrity metadata
**ID:** `evidence-record-integrity`
Time-sensitive live, manual, and drill evidence SHALL identify the tested revision or generation, environment, source persona, observation time, freshness boundary, limitations, mutation blast radius, and cleanup result without recording secrets.

#### Scenario: Live evidence lacks provenance
**ID:** `unattributed-live-evidence-is-stale`
- **WHEN** a live evidence record cannot identify its tested system, time, or freshness boundary
- **THEN** enforcement reports it as unusable or stale rather than current proof

### Requirement: Reusable evidence families demonstrate fault sensitivity
**ID:** `evidence-family-fault-detection`
Each reusable evidence family SHALL demonstrate, when introduced or materially rewritten, that it detects a representative injected defect and fails for the intended reason.

#### Scenario: Evidence family receives a representative mutant
**ID:** `representative-mutant-is-detected`
- **WHEN** a declared representative defect is introduced into the evidence family's isolated fixture
- **THEN** the family fails at the assertion that owns that defect and retains the distinguishing diagnostic

### Requirement: Semantic adequacy receives independent review
**ID:** `enforcement-quality-review`
Claims that automation cannot honestly establish about evidence adequacy, independence, production-path fidelity, or maintenance value SHALL receive independent Enforcement-lens review instead of a hollow automated substitute.

#### Scenario: Mechanical conformance passes but meaning is unclear
**ID:** `semantic-residue-is-reviewed`
- **WHEN** a binding is structurally valid but its source may not exercise the requirement
- **THEN** the Enforcement lens judges the semantic residue and records the limitation without upgrading it through helper-existence automation
