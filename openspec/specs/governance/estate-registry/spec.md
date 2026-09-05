---
id: governance.estate-registry
---

## Purpose

The repository keeps one small, human-maintained YAML inventory for finding homelab sites, hosts, addresses, storage details, and services.

## Requirements

### Requirement: Repository has one simple Estate inventory
**ID:** `single-estate-inventory`
The repository SHALL keep one valid `estate.yaml` file with hosts nested under sites and services listed on their host or VM.

#### Scenario: Inventory is checked after editing
**ID:** `inventory-parses`
- **WHEN** an operator checks the inventory after editing
- **THEN** it parses as YAML and its nested entries identify each host and service location

### Requirement: Estate inventory changes with catalogued facts
**ID:** `inventory-maintained-with-change`
A change to a catalogued site, host, address, storage detail, service placement, or service endpoint SHALL update `estate.yaml` in the same change.

#### Scenario: Service endpoint is introduced
**ID:** `service-endpoint-is-catalogued`
- **WHEN** a service gains an operator-facing URL
- **THEN** the same change records that URL in the service's inventory entry
