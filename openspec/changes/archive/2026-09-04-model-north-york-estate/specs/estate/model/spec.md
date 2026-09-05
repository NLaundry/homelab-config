---
id: estate.model
---

## MODIFIED Requirements

### Requirement: Inventory locates the managed Estate
**ID:** `inventory-locates-estate`
The Estate inventory SHALL identify every catalogued host's site and every catalogued service's host in one human-readable file.

#### Scenario: Current North York Estate is inspected
**ID:** `current-estate-is-located`
- **WHEN** an operator reads the Estate inventory
- **THEN** the North York site, its `10.10.10.0/24` LAN boundary, catalogued infrastructure hosts, and file-sharing service placement are directly visible without evaluating generated code
