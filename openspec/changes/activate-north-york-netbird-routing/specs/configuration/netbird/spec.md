---
id: configuration.netbird
---

## ADDED Requirements

### Requirement: North York routing is assigned
**ID:** `north-york-routing-assigned`
The North York Network SHALL assign its dedicated OPNsense router group as an enabled routing peer with an explicit metric and masquerading enabled.

#### Scenario: North York router configuration is evaluated
**ID:** `north-york-router-is-enabled`
- **WHEN** the NetBird configuration is evaluated
- **THEN** the North York Network resolves to the dedicated router group with the selected metric and masquerading

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
**Migration:** Assign the dedicated router group, enable masquerading, and activate the explicit administrator-to-resource policy through the staged routing procedure.
