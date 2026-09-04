---
id: governance.estate-registry
---

## Purpose

The repository keeps one small, human-maintained YAML inventory for finding homelab sites, hosts, addresses, storage details, and services.

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
