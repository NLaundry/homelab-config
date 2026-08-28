---
id: estate.model
---

## Purpose

The Estate model gives every managed logical entity and relationship one machine-readable identity so placement, dependency, and state ownership cannot become ambiguous as the homelab changes.

### Requirement: Managed Estate entities have typed logical identities
**ID:** `typed-logical-entities`
The Estate model SHALL represent every managed site, host role, workload, and durable state item as exactly one typed logical node with a stable identity.

#### Scenario: Current Estate is enumerated
**ID:** `current-estate-is-typed`
- **WHEN** the evaluated Estate model is inspected
- **THEN** the Home site, NAS role, file-sharing workload, `mediaBin` state, and `smolBoy` state each resolve to one typed logical node

### Requirement: Estate relationships resolve to allowed nodes
**ID:** `relationship-references-resolve`
Every Estate relationship SHALL reference an existing node of the relationship's allowed target kind.

#### Scenario: Unknown placement target is declared
**ID:** `unknown-target-is-rejected`
- **WHEN** a host, workload, or state relationship references an undeclared target
- **THEN** Estate enforcement reports the subject, allowed target kind, and unknown reference

### Requirement: Workloads have one placement
**ID:** `single-workload-placement`
Every managed workload SHALL have exactly one authoritative host placement.

#### Scenario: Workload placement cardinality is invalid
**ID:** `invalid-workload-placement-count`
- **WHEN** a workload has zero or multiple host placements
- **THEN** Estate enforcement reports the workload and observed placement set

### Requirement: Durable state has one authoritative owner
**ID:** `single-state-owner`
Every managed durable state node SHALL have exactly one authoritative host owner.

#### Scenario: State ownership cardinality is invalid
**ID:** `invalid-state-owner-count`
- **WHEN** a durable state node has zero or multiple authoritative owners
- **THEN** Estate enforcement reports the state node and observed owner set

### Requirement: Workload state dependencies are explicit
**ID:** `workload-state-dependencies-explicit`
Every managed workload dependency on durable state SHALL be represented by an explicit workload-to-state relationship.

#### Scenario: File-sharing dependencies are inspected
**ID:** `file-sharing-state-dependencies-resolve`
- **WHEN** the file-sharing workload is inspected
- **THEN** its dependencies resolve explicitly to the `mediaBin` and `smolBoy` state nodes
