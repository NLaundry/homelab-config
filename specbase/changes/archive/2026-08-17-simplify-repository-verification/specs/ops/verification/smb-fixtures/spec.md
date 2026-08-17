---
id: ops.verification.smb-fixtures
---

## Purpose

This retired pair previously operated the hidden Samba fixture endpoint, storage, auditing, and recovery procedure.

## REMOVED Requirements

### Requirement: Samba realizes the dedicated fixture endpoint
**ID:** `verification-share-realized`
**Reason:** The hidden test-only endpoint is retired.
**Migration:** Remove the Samba share and verify ordinary guest shares directly.

### Requirement: Ordinary SMB shares deny the tester principal
**ID:** `ordinary-shares-deny-tester`
**Reason:** No tester principal remains to deny.
**Migration:** Preserve ordinary guest semantics and remove tester-specific share configuration.

### Requirement: Verification storage is bounded and root-controlled
**ID:** `verification-storage-bounded`
**Reason:** Dedicated fixture storage is removed with the endpoint.
**Migration:** Remove its tmpfs, initialization unit, and capacity profiles.

### Requirement: Verification mutations are audited
**ID:** `verification-audit-enabled`
**Reason:** The dedicated mutation identity and fixture state are removed.
**Migration:** Remove fixture-specific Samba audit configuration; no replacement audit contract is introduced.

### Requirement: Residual fixture state has an exact recovery procedure
**ID:** `fixture-recovery-procedure`
**Reason:** The fixture service and persistent recovery lifecycle are retired.
**Migration:** Direct guest verification reports exact cleanup failure within its own run; the former recovery procedure is removed.
