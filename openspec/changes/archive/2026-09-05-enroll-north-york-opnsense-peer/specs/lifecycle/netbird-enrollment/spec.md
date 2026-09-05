---
id: lifecycle.netbird-enrollment
---

## Purpose

NetBird peer enrollment verifies compatibility, avoids duplicate identity, and keeps its one-use credential ephemeral.

## ADDED Requirements

### Requirement: Router enrollment is preflighted
**ID:** `netbird-enrollment-preflighted`
The enrollment operation SHALL verify the installed plugin and every API endpoint it will use before mutating OPNsense.

#### Scenario: A required endpoint is unavailable
**ID:** `enrollment-stops-on-failed-preflight`
- **WHEN** a required read-only API request fails
- **THEN** enrollment stops without changing plugin settings or service state

### Requirement: Router enrollment is idempotent
**ID:** `netbird-enrollment-idempotent`
A repeated enrollment operation SHALL reuse the existing intended peer without requiring another setup key.

#### Scenario: Enrolled router is processed again
**ID:** `existing-peer-is-reused`
- **WHEN** the enrollment operation finds the intended connected local and remote peer identity
- **THEN** it performs no new authentication or peer creation

### Requirement: Enrollment setup keys are ephemeral
**ID:** `setup-key-ephemeral`
A NetBird setup key SHALL be one-use, have no automatic group assignment, be entered only through the official OPNsense authentication interface, and be deleted from NetBird after the result is known. Any value retained by the official plugin SHALL be unusable after one-use consumption or remote deletion.

#### Scenario: Enrollment attempt completes
**ID:** `setup-key-is-retired`
- **WHEN** an OPNsense peer enrollment succeeds or fails
- **THEN** its setup key is absent from Git, SOPS, OpenTofu state, command arguments, and logs, is deleted from NetBird, and cannot authorize another enrollment
