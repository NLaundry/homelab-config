---
id: configuration.netbird
---

## Purpose

NetBird configuration declares the selected North York control-plane objects while leaving LAN routing disabled.

## Requirements

### Requirement: North York Network is declared
**ID:** `north-york-network-declared`
The NetBird configuration SHALL declare one North York Network, one dedicated peer-free resource group, and its selected LAN resource.

#### Scenario: North York configuration is evaluated
**ID:** `north-york-baseline-resolves`
- **WHEN** the NetBird configuration is evaluated
- **THEN** the North York Network, dedicated resource group, and `10.10.10.0/24` LAN resource resolve without a second-site declaration
- **AND** the LAN resource belongs to that group and the group contains no peers

### Requirement: NetBird provider selection is pinned
**ID:** `netbird-provider-pinned`
The NetBird configuration SHALL constrain and lock its provider selection for every supported operator platform.

#### Scenario: Provider initialization repeats
**ID:** `provider-selection-repeats`
- **WHEN** initialization runs again without an approved upgrade
- **THEN** it selects the committed provider version and checksums

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
