## Purpose

Configure OPNsense to obtain and renew its WebGUI certificate from the homelab's internal ACME-capable certificate authority rather than relying on a self-signed certificate.

## ADDED Requirements

### Requirement: Bootstrap the internal-CA certificate configuration

Ansible SHALL be able to create and configure the OPNsense ACME account, internal-CA directory, HTTP-01 validation, WebGUI reload action, certificate definition, and native renewal settings when the target APIs support those operations.

#### Scenario: Create the router ACME configuration

- **WHEN** an operator runs the explicit ACME bootstrap with the approved internal-CA directory and router hostname
- **THEN** OPNsense contains an enabled account, validation, reload action, certificate definition, and renewal schedule for that hostname

#### Scenario: Missing bootstrap capability

- **WHEN** a required ACME API operation is unavailable or rejected
- **THEN** the playbook fails clearly and does not substitute a self-signed certificate

### Requirement: Preserve native ACME renewal ownership

Ansible SHALL configure OPNsense's native ACME renewal process and SHALL preserve the account, certificate, validation, automation, and renewal identities across repeat runs.

#### Scenario: Repeat an unchanged ACME run

- **WHEN** the existing native ACME configuration matches the desired internal-CA configuration
- **THEN** the playbook makes no configuration change and does not request an unnecessary renewal

#### Scenario: Update renewal configuration

- **WHEN** an owned ACME setting or native renewal schedule differs from the desired value
- **THEN** the playbook updates that setting without replacing the existing native identities

### Requirement: Leave certificate acceptance to live verification

Ansible SHALL fail on rejected ACME configuration operations but SHALL NOT treat saved configuration or an API acknowledgement as proof that a valid certificate is being served.

#### Scenario: Configuration succeeds

- **WHEN** OPNsense accepts the ACME configuration
- **THEN** the live verification suite separately checks issuer, hostname, trust chain, served certificate, and renewal health
