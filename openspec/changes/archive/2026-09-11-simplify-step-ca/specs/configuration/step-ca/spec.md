## Purpose

Provide a private certificate authority for automatically issued service certificates across the `laundrylab.internal` namespace without brittle per-name configuration or unnecessary runtime machinery.

## ADDED Requirements

### Requirement: Issue private service certificates through ACME

The authority SHALL support ACME issuance for exact DNS names under `laundrylab.internal` when the requesting client completes the configured ACME authorization challenge. Issuance SHALL NOT depend on enumerating every permitted service name in a CA-wide exact-name list.

#### Scenario: Issue a certificate for a new internal service

- **WHEN** an ACME client requests an exact internal DNS name and completes authorization for that name
- **THEN** the authority issues a server certificate for that name without requiring a configuration change to add the name first

#### Scenario: Reject a name outside the private namespace

- **WHEN** an ACME client requests a DNS name outside `laundrylab.internal`
- **THEN** the order or certificate request fails and no certificate is issued

### Requirement: Preserve the dedicated OPNsense certificate boundary

The authority SHALL retain a dedicated OPNsense ACME issuance path that issues only a server certificate for `opnsense.ny.laundrylab.internal`, with no additional SANs or alternate common name.

#### Scenario: Renew the OPNsense certificate

- **WHEN** OPNsense completes ACME authorization for `opnsense.ny.laundrylab.internal`
- **THEN** the issued certificate contains that DNS name as its only SAN and remains suitable for WebGUI server authentication

#### Scenario: Reject an alternate OPNsense identifier

- **WHEN** the OPNsense ACME client requests another hostname, an extra SAN, or a wildcard
- **THEN** certificate issuance fails and the existing valid certificate is not replaced by an unauthorized certificate

### Requirement: Keep wildcard issuance disabled

The authority SHALL reject wildcard DNS identifiers for all current service certificate issuance paths.

#### Scenario: Reject a wildcard request

- **WHEN** an ACME client requests a certificate containing a wildcard DNS identifier
- **THEN** the request fails even if the client can complete an ACME challenge for a matching domain

### Requirement: Use ACME without direct operator payload staging

The authority SHALL be able to start and issue certificates through its ACME provisioners without requiring a manually staged direct-operator signing payload. Current service issuance SHALL use ACME authorization rather than direct administrative certificate signing.

#### Scenario: Start with the commissioned CA state

- **WHEN** the guest starts with its existing persistent CA state, protected intermediate key, and declared ACME configuration
- **THEN** the CA starts without requiring a separate runtime-assembled operator payload

#### Scenario: Failed ACME authorization

- **WHEN** an ACME client cannot complete authorization or requests an unauthorized certificate name
- **THEN** the request fails clearly, no certificate is issued, and the CA remains available for valid requests

### Requirement: Preserve the commissioned trust hierarchy and issuance state

The change SHALL preserve the existing LaundryLab root identity, commissioned intermediate identity, persistent issuance database, and existing ACME account and certificate continuity. It SHALL NOT require authority reinitialization or replacement of the trust anchor.

#### Scenario: Restart after configuration change

- **WHEN** the CA restarts after the ACME-first configuration is applied
- **THEN** it serves the same commissioned intermediate chain and existing ACME clients can continue renewal without re-enrollment

#### Scenario: Invalid or incomplete commissioned state

- **WHEN** required commissioned state or the protected intermediate key is missing, invalid, or inconsistent
- **THEN** the service refuses to issue certificates rather than creating replacement authority state

### Requirement: Keep current service certificates server-only

The current ACME service certificate paths SHALL issue certificates for server authentication only. Client authentication certificates and SSH certificates SHALL be introduced through separate, explicitly designed capabilities.

#### Scenario: Use a service certificate for HTTPS

- **WHEN** an authorized ACME client receives a certificate through a current service provisioner
- **THEN** the certificate is suitable for TLS server authentication and does not silently become a client identity credential
