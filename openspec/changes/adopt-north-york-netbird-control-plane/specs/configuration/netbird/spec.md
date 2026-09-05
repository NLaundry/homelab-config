---
id: configuration.netbird
---

## Purpose

NetBird configuration declares the selected private-network objects and their bounded access realization.

## ADDED Requirements

### Requirement: North York Network is declared
**ID:** `north-york-network-declared`
The NetBird configuration SHALL declare one North York Network, its selected LAN resource, and its dedicated router group.

#### Scenario: North York configuration is evaluated
**ID:** `north-york-baseline-resolves`
- **WHEN** the NetBird configuration is evaluated
- **THEN** the North York Network, LAN resource, and router group resolve without a second-site declaration

### Requirement: North York routing remains unassigned
**ID:** `north-york-routing-unassigned`
The North York Network SHALL have no routing peer assignment or effective routed-LAN access policy in this baseline.

#### Scenario: Baseline is applied
**ID:** `baseline-does-not-route-lan`
- **WHEN** the North York baseline has been applied
- **THEN** no NetBird peer can route traffic to the North York LAN through that Network

### Requirement: NetBird provider selection is pinned
**ID:** `netbird-provider-pinned`
The NetBird configuration SHALL constrain and lock its provider selection for every supported operator platform.

#### Scenario: Provider initialization repeats
**ID:** `provider-selection-repeats`
- **WHEN** initialization runs again without an approved upgrade
- **THEN** it selects the committed provider version and checksums
