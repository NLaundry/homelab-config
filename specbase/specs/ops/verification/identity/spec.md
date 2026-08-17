---
id: ops.verification.identity
---

### Requirement: The NAS provisions the tester Unix account
**ID:** `tester-account-provisioned`
The NAS configuration SHALL provision a locked, non-login Unix account for the testing role without sudo, SSH authorization, or deployment membership.

#### Scenario: The tester account is evaluated
**ID:** `tester-account-constrained`
- **WHEN** the NAS account configuration is evaluated
- **THEN** the tester exists and has none of the prohibited interactive or privileged memberships

### Requirement: The Samba tester principal has an operator lifecycle
**ID:** `tester-principal-managed`
The repository SHALL provide an operator procedure that provisions, verifies, rotates, revokes active sessions for, and retires the Samba testing principal.

#### Scenario: The tester principal is retired
**ID:** `tester-principal-retired`
- **WHEN** an operator completes principal retirement
- **THEN** active tester sessions are terminated and new tester authentication is rejected

### Requirement: Tester credentials remain outside repository outputs
**ID:** `tester-secret-external`
The testing credential SHALL NOT appear in tracked files, Nix derivations or store outputs, process arguments, or captured test output.

#### Scenario: Live verification receives a credential
**ID:** `credential-supplied-out-of-band`
- **WHEN** the live client authenticates as the tester
- **THEN** it reads the credential from an operator-controlled secret file without printing its value

### Requirement: Tester credentials are rotatable
**ID:** `tester-secret-rotatable`
Credential rotation SHALL terminate active tester sessions, reject the previous credential for new sessions, and accept the replacement credential.

#### Scenario: An operator rotates the tester credential
**ID:** `credential-rotation-verified`
- **WHEN** the rotation procedure completes
- **THEN** prior sessions are closed and only the replacement credential opens a new session
