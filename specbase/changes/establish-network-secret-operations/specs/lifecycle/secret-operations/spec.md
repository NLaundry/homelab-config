---
id: lifecycle.secret-operations
---

## Purpose

Secret custody remains recoverable and long-lived network credentials can be replaced without leaving obsolete access material behind.

## ADDED Requirements

### Requirement: Operator secret access is recoverable
**ID:** `operator-secret-recovery`
An operator SHALL be able to restore authorized decryption capability from the documented recovery material without retrieving a private identity from the repository.

#### Scenario: Primary operator identity is unavailable
**ID:** `operator-recovers-with-backup`
- **WHEN** the primary local age identity is unavailable
- **THEN** the documented recovery procedure restores access to dummy ciphertext using independently held material

### Requirement: Long-lived network credentials are rotated safely
**ID:** `network-credential-rotation`
The credential rotation procedure SHALL validate each replacement before revoking its predecessor and SHALL retain no plaintext credential evidence.

#### Scenario: Network credential is replaced
**ID:** `replacement-precedes-revocation`
- **WHEN** an operator rotates a NetBird or OPNsense API credential
- **THEN** the replacement is proven usable before the previous credential is revoked
