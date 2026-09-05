---
id: configuration.opnsense-netbird
---

## MODIFIED Requirements

### Requirement: NetBird interface is assigned
**ID:** `opnsense-wt0-assigned`
North York OPNsense SHALL assign the NetBird `wt0` device and limit its active persistent routed-access rule to the selected overlay source and North York LAN destination.

#### Scenario: Routed router interfaces are inspected
**ID:** `wt0-routing-boundary`
- **WHEN** the activated router's interface and firewall configuration is read
- **THEN** `wt0` is assigned and its active routed rule is bounded to the declared overlay source and North York LAN destination
