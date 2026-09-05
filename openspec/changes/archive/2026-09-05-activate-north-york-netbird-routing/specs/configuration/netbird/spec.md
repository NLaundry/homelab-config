---
id: configuration.netbird
---

## ADDED Requirements

### Requirement: North York routing is assigned
**ID:** `north-york-routing-assigned`
The North York Network SHALL directly assign its uniquely identified connected OPNsense peer as an enabled router with an explicit metric and masquerading enabled.

#### Scenario: North York router configuration is evaluated
**ID:** `north-york-router-is-enabled`
- **WHEN** the NetBird configuration is evaluated
- **THEN** the North York Network resolves to the selected OPNsense peer with the selected metric and masquerading

### Requirement: North York administrator policy is explicit
**ID:** `north-york-admin-policy-explicit`
The NetBird configuration SHALL grant North York LAN access from an explicit administrator source group to an explicit North York resource destination without granting reverse initiation.

#### Scenario: North York access policy is evaluated
**ID:** `policy-has-bounded-groups`
- **WHEN** the managed North York policy is evaluated
- **THEN** its source and destination are the selected groups and its direction permits administrator initiation only

## REMOVED Requirements

### Requirement: North York routing remains unassigned
**ID:** `north-york-routing-unassigned`
**Reason:** The enrolled North York OPNsense peer is now ready to provide the intended routed access.
**Migration:** Directly assign the OPNsense peer, enable masquerading, and activate the approved administrator-to-resource policy.
