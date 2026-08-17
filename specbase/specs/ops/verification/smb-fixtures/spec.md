---
id: ops.verification.smb-fixtures
---

### Requirement: Samba realizes the dedicated fixture endpoint
**ID:** `verification-share-realized`
The NAS Samba configuration SHALL define a non-browseable verification share rooted at dedicated state, require the testing principal, and disable traversal outside the share root.

#### Scenario: The verification share is evaluated
**ID:** `verification-share-confined`
- **WHEN** the NAS Samba configuration is evaluated
- **THEN** the hidden share resolves to the dedicated root and requires the tester credential

### Requirement: Ordinary SMB shares deny the tester principal
**ID:** `ordinary-shares-deny-tester`
The NAS Samba configuration SHALL explicitly deny the testing principal on every ordinary-data share without changing those shares' guest-access semantics.

#### Scenario: The tester addresses an ordinary share
**ID:** `tester-ordinary-share-rejected`
- **WHEN** the tester credential addresses an ordinary-data share
- **THEN** Samba rejects access rather than forcing the session to an operator identity

### Requirement: Verification storage is bounded and root-controlled
**ID:** `verification-storage-bounded`
The verification share backing state SHALL enforce finite byte and inode capacity, keep its root metadata outside tester control, and reject link traversal beyond the root.

#### Scenario: The backing state is evaluated
**ID:** `verification-storage-controls-present`
- **WHEN** the verification storage configuration is inspected
- **THEN** capacity, root ownership, and link-containment controls are present

### Requirement: Verification mutations are audited
**ID:** `verification-audit-enabled`
The NAS SHALL record successful fixture namespace and file mutations with the authenticated principal, client, share, operation, and affected path in operator-readable, tester-nonwritable logs.

#### Scenario: A fixture path changes
**ID:** `fixture-operation-logged`
- **WHEN** the tester creates, writes, renames, or removes a run-scoped fixture
- **THEN** the NAS audit output records the tester, client, share, operation, and path containing the run identity

### Requirement: Residual fixture state has an exact recovery procedure
**ID:** `fixture-recovery-procedure`
The repository SHALL provide an operator recovery procedure that revokes active tester sessions, validates one reported run identity beneath the verification root, and removes or quarantines exactly that namespace.

#### Scenario: Automated cleanup leaves residue
**ID:** `operator-recovers-one-run`
- **WHEN** a failed test reports a residual run identity
- **THEN** the operator procedure rejects targets outside the root and recovers only that run namespace
