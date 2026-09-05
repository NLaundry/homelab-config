---
id: governance.estate-registry
---

## Purpose

The repository keeps one small, human-maintained YAML inventory for finding homelab sites, hosts, addresses, storage details, and services.

## ADDED Requirements

### Requirement: Repository has one simple Estate inventory
**ID:** `single-estate-inventory`
The repository SHALL keep the operator Estate inventory as a valid `estate.yaml` file with site, host, and service maps.

#### Scenario: Inventory is checked after editing
**ID:** `inventory-parses`
- **WHEN** the focused Estate check runs
- **THEN** the inventory parses and exposes the expected top-level maps

### Requirement: Estate inventory changes with catalogued facts
**ID:** `inventory-maintained-with-change`
A change to a catalogued site, host, address, storage detail, service placement, or service endpoint SHALL update `estate.yaml` in the same change.

#### Scenario: Service endpoint is introduced
**ID:** `service-endpoint-is-catalogued`
- **WHEN** a service gains an operator-facing URL
- **THEN** the same change records that URL in the service's inventory entry

## REMOVED Requirements

### Requirement: Registry schema is typed and bounded
**ID:** `typed-bounded-schema`
**Reason:** A generic typed schema is unnecessary for a small operator inventory.
**Migration:** Use the shallow YAML shape checked by `tests/estate/inventory.bats`.

### Requirement: Registry export is deterministic and JSON-safe
**ID:** `normalized-json-export`
**Reason:** The inventory is read directly and no generated graph export remains.
**Migration:** Review the YAML directly and use Git for history.

### Requirement: Graph violations are structured and stable
**ID:** `structured-graph-violations`
**Reason:** There is no graph validator after simplification.
**Migration:** The focused check reports parse, shape, and missing-reference failures.

### Requirement: Graph diff reports semantic changes
**ID:** `normalized-graph-diff`
**Reason:** A custom semantic diff duplicates Git without a current consumer.
**Migration:** Review ordinary YAML diffs.

### Requirement: Registry fixtures demonstrate fault sensitivity
**ID:** `registry-fault-fixtures`
**Reason:** The mutation suite mostly tested infrastructure that is being removed.
**Migration:** Keep one direct inventory check against the real file.

### Requirement: Reconciliation keeps expected and observed topology separate
**ID:** `independent-estate-reconciliation`
**Reason:** The narrow evaluator comparison did not establish deployed or live topology.
**Migration:** Treat the YAML as descriptive inventory and retain independent deployment and live checks for their existing claims.
