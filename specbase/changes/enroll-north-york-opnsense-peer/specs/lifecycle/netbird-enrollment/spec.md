---
id: lifecycle.netbird-enrollment
---

## Purpose

NetBird peer enrollment protects router availability, avoids duplicate identity, retires one-use credentials, and remains reversible before routing activation.

## ADDED Requirements

### Requirement: Router enrollment is preflighted
**ID:** `netbird-enrollment-preflighted`
The enrollment operation SHALL verify compatibility, configuration backup, and a working local management path before mutating OPNsense.

#### Scenario: Recovery prerequisite is missing
**ID:** `enrollment-stops-without-recovery-path`
- **WHEN** backup or local management preflight fails
- **THEN** enrollment stops without installing, assigning, or authenticating the plugin

### Requirement: Router enrollment is idempotent
**ID:** `netbird-enrollment-idempotent`
A repeated enrollment operation SHALL reconcile the existing intended peer without generating another peer identity or setup key.

#### Scenario: Enrolled router is processed again
**ID:** `existing-peer-is-reused`
- **WHEN** the enrollment operation finds the intended connected local and remote peer identity
- **THEN** it updates only drifted managed settings and performs no new enrollment

### Requirement: Enrollment setup keys are ephemeral
**ID:** `setup-key-ephemeral`
A NetBird setup key SHALL be generated for one enrollment, consumed through volatile runtime state, and revoked or deleted after the enrollment result is known.

#### Scenario: Enrollment attempt completes
**ID:** `setup-key-is-retired`
- **WHEN** an OPNsense peer enrollment succeeds or fails
- **THEN** its setup key is absent from tracked secrets and OpenTofu state and is no longer valid for another enrollment

### Requirement: Router enrollment is reversible
**ID:** `opnsense-peer-rollback`
An operator SHALL be able to disconnect and remove role-owned NetBird configuration while retaining local OPNsense administration and unrelated router services.

#### Scenario: Enrolled prefix is rolled back
**ID:** `rollback-preserves-router-management`
- **WHEN** the documented pre-routing rollback is executed
- **THEN** the NetBird peer and role-owned interface/firewall state are removed or disabled while local router management remains reachable
