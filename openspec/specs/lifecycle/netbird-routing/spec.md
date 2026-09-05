---
id: lifecycle.netbird-routing
---

## Purpose

NetBird routing is accepted only after a real routed connection succeeds and can be withdrawn while retaining the enrolled peer.

## Requirements

### Requirement: Routing activation is verified
**ID:** `netbird-routing-activation-safe`
Routing activation SHALL retain local OPNsense management and demonstrate an approved service connection through NetBird from outside the North York LAN.

#### Scenario: Activation verification fails
**ID:** `failed-activation-withdraws-access`
- **WHEN** the routed connection or local management check fails
- **THEN** activation is withdrawn and is not reported as complete

### Requirement: Routing rollback preserves the enrolled prefix
**ID:** `netbird-routing-rollback-safe`
Routing rollback SHALL disable the access policy and router assignment and restore changed plugin routing settings while retaining the enrolled peer and baseline Network/resource/group.

#### Scenario: Operator withdraws North York routing
**ID:** `rollback-retains-peer-baseline`
- **WHEN** the routing rollback procedure completes
- **THEN** routed North York access is absent while the OPNsense peer remains connected and locally manageable
