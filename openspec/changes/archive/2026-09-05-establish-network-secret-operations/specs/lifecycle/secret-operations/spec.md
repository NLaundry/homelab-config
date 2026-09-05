---
id: lifecycle.secret-operations
---

## Purpose

Secret custody remains recoverable and long-lived network credentials can be replaced without leaving obsolete access material behind.

## ADDED Requirements

### Requirement: Operator secret access is recoverable
**ID:** `operator-secret-recovery`
An operator SHALL be able to retrieve a valid authorized identity from documented recovery material without retrieving private material from the repository.

#### Scenario: Recovery identity is verified
**ID:** `operator-recovers-with-backup`
- **WHEN** the independently held recovery identity is retrieved
- **THEN** it parses successfully and derives the declared public recipient without exposing private material in evidence

### Requirement: Long-lived network credentials are rotated safely
**ID:** `network-credential-rotation`
The credential rotation procedure SHALL validate each replacement before revoking its predecessor and SHALL retain no plaintext credential evidence.

#### Scenario: Network credential is replaced
**ID:** `replacement-precedes-revocation`
- **WHEN** an operator rotates a NetBird or OPNsense API credential
- **THEN** the replacement is proven usable through the locally verified consumer's scoped read-only authentication check before the previous credential is revoked
- **AND** neither credential is printed or written to a runtime credential file
