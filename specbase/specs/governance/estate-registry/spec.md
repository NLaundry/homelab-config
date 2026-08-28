---
id: governance.estate-registry
---

## Purpose

The repository provides a typed, deterministic Estate registry instrument that exports, validates, diffs, and reconciles desired topology without absorbing Configuration or runtime truth.

### Requirement: Registry schema is typed and bounded
**ID:** `typed-bounded-schema`
The Estate registry instrument SHALL accept only the selected site, host, workload, and durable-state record shapes and SHALL exclude secrets, derivations, packages, and arbitrary NixOS configuration.

#### Scenario: Registry shape is evaluated
**ID:** `selected-schema-evaluates`
- **WHEN** a valid registry declaration is evaluated
- **THEN** every record conforms to one selected node shape and no Configuration payload is exported

### Requirement: Registry export is deterministic and JSON-safe
**ID:** `normalized-json-export`
The Estate registry instrument SHALL export a schema version plus sorted JSON-safe nodes and relationships whose identities do not depend on declaration order.

#### Scenario: Equivalent declarations are normalized
**ID:** `declaration-order-is-ignored`
- **WHEN** equivalent records are declared in a different order
- **THEN** the normalized export remains equal

### Requirement: Graph violations are structured and stable
**ID:** `structured-graph-violations`
The Estate registry instrument SHALL report every semantic graph violation with a stable code, subject identity, expected property, and observed references.

#### Scenario: Invalid placement is diagnosed
**ID:** `invalid-placement-has-structured-diagnostic`
- **WHEN** a workload placement violates reference or cardinality rules
- **THEN** the diagnostic identifies the workload, violation code, expected host property, and observed placements

### Requirement: Graph diff reports semantic changes
**ID:** `normalized-graph-diff`
The Estate registry instrument SHALL report sorted node and relationship additions and removals, SHALL represent placement or ownership changes as scoped remove/add pairs, and SHALL ignore declaration-order and source-layout noise.

#### Scenario: Workload moves between hosts
**ID:** `placement-move-is-diffed`
- **WHEN** a workload's authoritative placement changes
- **THEN** the diff reports the removed and added placement relationships without unrelated changes

### Requirement: Registry fixtures demonstrate fault sensitivity
**ID:** `registry-fault-fixtures`
The Estate registry instrument SHALL demonstrate detection of representative reference, placement-cardinality, ownership-cardinality, and dangling-removal defects through the production validator.

#### Scenario: Representative invalid registry is evaluated
**ID:** `invalid-fixture-fails-owned-property`
- **WHEN** an invalid fixture is evaluated
- **THEN** the production validator emits the intended code and subject and the valid control remains clean

### Requirement: Reconciliation keeps expected and observed topology separate
**ID:** `independent-estate-reconciliation`
The Estate registry instrument SHALL compare declared placement and ownership with independently evaluated selected host facts and SHALL report model-only and physical limitations explicitly.

#### Scenario: NAS realization contradicts Estate declaration
**ID:** `nas-drift-is-reported`
- **WHEN** evaluated NAS service or pool facts contradict the declared file-sharing placement or state ownership
- **THEN** reconciliation reports the graph subject, expected relation, observed fact, and unproven physical residue
