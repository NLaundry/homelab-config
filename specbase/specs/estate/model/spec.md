---
id: estate.model
---

## Purpose

The Estate inventory gives operators one readable catalogue of homelab sites, hosts, practical host details, and service placement.

### Requirement: Inventory locates the managed Estate
**ID:** `inventory-locates-estate`
The Estate inventory SHALL identify every catalogued host's site and every catalogued service's host in one human-readable file.

#### Scenario: Current Estate is inspected
**ID:** `current-estate-is-located`
- **WHEN** an operator reads the Estate inventory
- **THEN** the Home site, NAS host, and file-sharing service placement are directly visible without evaluating generated code
