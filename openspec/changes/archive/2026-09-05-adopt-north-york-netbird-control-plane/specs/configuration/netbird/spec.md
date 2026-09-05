---
id: configuration.netbird
---

## Purpose

NetBird configuration declares the selected North York control-plane objects while leaving LAN routing disabled.

## ADDED Requirements

### Requirement: North York Network is declared
**ID:** `north-york-network-declared`
The NetBird configuration SHALL declare one North York Network, one dedicated peer-free resource group, and its selected LAN resource.

#### Scenario: North York configuration is evaluated
**ID:** `north-york-baseline-resolves`
- **WHEN** the NetBird configuration is evaluated
- **THEN** the North York Network, dedicated resource group, and `10.10.10.0/24` LAN resource resolve without a second-site declaration
- **AND** the LAN resource belongs to that group and the group contains no peers

### Requirement: North York routing remains unassigned
**ID:** `north-york-routing-unassigned`
The North York baseline SHALL contain no peer, router group, router assignment, or effective routed-LAN access policy; its resource group SHALL contain no peers.

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
