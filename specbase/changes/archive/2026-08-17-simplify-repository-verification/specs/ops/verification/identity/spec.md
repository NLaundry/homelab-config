---
id: ops.verification.identity
---

## Purpose

This retired pair previously governed provisioning and secret lifecycle for the dedicated Samba verification identity.

## REMOVED Requirements

### Requirement: The NAS provisions the tester Unix account
**ID:** `tester-account-provisioned`
**Reason:** The dedicated test identity is retired with the hidden verification endpoint.
**Migration:** Remove the account and its configuration.

### Requirement: The Samba tester principal has an operator lifecycle
**ID:** `tester-principal-managed`
**Reason:** No persistent Samba tester principal remains.
**Migration:** Retire the provisioning, rotation, session-revocation, and deletion procedure.

### Requirement: Tester credentials remain outside repository outputs
**ID:** `tester-secret-external`
**Reason:** Live default verification no longer requires a secret credential.
**Migration:** Remove repository references; operators may delete obsolete external files after rollback confidence is established.

### Requirement: Tester credentials are rotatable
**ID:** `tester-secret-rotatable`
**Reason:** The credential is retired rather than retained and rotated.
**Migration:** Remove rotation evidence and do not create a replacement secret.
