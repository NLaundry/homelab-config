---
id: behavior.verification.smb-fixtures
---

### Requirement: The tester can authenticate to the verification endpoint
**ID:** `tester-authenticated`
A live verification client presenting the current testing credential SHALL be accepted by the dedicated SMB verification endpoint.

#### Scenario: Current tester credentials are presented
**ID:** `tester-access-accepted`
- **WHEN** a verification client connects with the current testing credential
- **THEN** the endpoint accepts the authenticated session

### Requirement: The verification endpoint requires the testing credential
**ID:** `tester-credential-required`
The dedicated SMB verification endpoint SHALL deny any client that does not present the current testing credential.

#### Scenario: A guest addresses the hidden endpoint
**ID:** `guest-access-rejected`
- **WHEN** an unauthenticated client addresses the verification endpoint by name
- **THEN** the endpoint rejects access

#### Scenario: A retired credential is presented
**ID:** `retired-credential-rejected`
- **WHEN** a client presents the tester credential replaced by the latest rotation
- **THEN** the endpoint rejects access

### Requirement: The tester can complete a disposable fixture transaction
**ID:** `fixture-transaction`
Within a namespace created for the current verification run, the testing identity SHALL be able to create, read, and remove a fixture and observe that the namespace no longer remains.

#### Scenario: A live SMB fixture is exercised
**ID:** `fixture-round-trip`
- **WHEN** the testing identity writes unique content beneath its run namespace
- **THEN** the client reads the same content, removes the namespace, and observes its absence

### Requirement: Accepted mutations are attributable
**ID:** `mutation-attribution`
For every accepted verification mutation, an operator SHALL be able to identify the testing identity, client, operation, and run-scoped resource from the NAS audit record.

#### Scenario: A tester creates a fixture file
**ID:** `fixture-write-attributed`
- **WHEN** the testing identity creates a file beneath its run namespace
- **THEN** the audit record identifies the tester, client, creation operation, and run-scoped path
