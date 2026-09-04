---
id: estate.model
---

## Purpose

The Estate inventory gives operators one readable catalogue of homelab sites, hosts, practical host details, and service placement.

## ADDED Requirements

### Requirement: Inventory locates the managed Estate
**ID:** `inventory-locates-estate`
The Estate inventory SHALL identify every catalogued host's site and every catalogued service's host in one human-readable file.

#### Scenario: Current Estate is inspected
**ID:** `current-estate-is-located`
- **WHEN** an operator reads the Estate inventory
- **THEN** the Home site, NAS host, and file-sharing service placement are directly visible without evaluating generated code

## REMOVED Requirements

### Requirement: Managed Estate entities have typed logical identities
**ID:** `typed-logical-entities`
**Reason:** Typed logical nodes add machinery without improving the current operator inventory.
**Migration:** Represent sites, hosts, and services directly in `estate.yaml`.

### Requirement: Estate relationships resolve to allowed nodes
**ID:** `relationship-references-resolve`
**Reason:** Generic graph relationship types are being removed.
**Migration:** The small inventory check verifies only host-to-site and service-to-host references.

### Requirement: Workloads have one placement
**ID:** `single-workload-placement`
**Reason:** A generic placement-cardinality model is unnecessary for the current inventory.
**Migration:** Each catalogued service has one `host` value in `estate.yaml`.

### Requirement: Durable state has one authoritative owner
**ID:** `single-state-owner`
**Reason:** Durable state nodes and ownership edges are being removed from the inventory model.
**Migration:** Practical storage details are recorded directly on the host when useful.

### Requirement: Workload state dependencies are explicit
**ID:** `workload-state-dependencies-explicit`
**Reason:** Workload-to-state graph edges are not needed to answer where current services and storage are.
**Migration:** Record service placement and host storage details directly in `estate.yaml`.
