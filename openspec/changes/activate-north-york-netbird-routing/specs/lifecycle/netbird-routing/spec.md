---
id: lifecycle.netbird-routing
---

## Purpose

NetBird routing can be activated and withdrawn without losing local router management, unrelated services, or the enrolled peer baseline.

## ADDED Requirements

### Requirement: Routing activation is safe
**ID:** `netbird-routing-activation-safe`
The routing activation SHALL retain local OPNsense management and SHALL commit its firewall savepoint only after authorized and unauthorized access checks produce the expected outcomes.

#### Scenario: Activation verification fails
**ID:** `failed-activation-reverts-firewall`
- **WHEN** a required plan, management, positive-access, or negative-access check fails during activation
- **THEN** the OPNsense savepoint is reverted or allowed to expire and routed access is not accepted as complete

### Requirement: Routing rollback preserves the enrolled prefix
**ID:** `netbird-routing-rollback-safe`
Routing rollback SHALL remove effective LAN access before disabling the OPNsense pass rule and SHALL preserve the enrolled OPNsense peer and unrouted North York baseline.

#### Scenario: Operator withdraws North York routing
**ID:** `rollback-retains-peer-baseline`
- **WHEN** the routing rollback procedure completes
- **THEN** routed North York access is absent while the OPNsense peer remains connected and locally manageable
