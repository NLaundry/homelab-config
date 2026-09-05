---
id: configuration.nas-realization
---

## ADDED Requirements

### Requirement: NAS inventory address is selected
**ID:** `nas-inventory-address`
The operator inventory SHALL record `10.10.10.11` as the selected LAN address for the NAS.

#### Scenario: NAS connection details are inspected
**ID:** `nas-lan-address-visible`
- **WHEN** an operator reads the NAS entry in the Estate inventory
- **THEN** the selected LAN address is directly visible
