---
id: configuration.network-secret-delivery
---

## Purpose

Network automation receives its selected credentials through encrypted storage and bounded runtime delivery channels.

## ADDED Requirements

### Requirement: Network credentials remain encrypted at rest
**ID:** `network-credentials-encrypted`
The managed NetBird and OPNsense credentials and OpenTofu state-encryption input SHALL remain encrypted whenever stored in the repository.

#### Scenario: Network credential document is at rest
**ID:** `network-document-is-ciphertext`
- **WHEN** the network credential document is read without an authorized age identity
- **THEN** no managed credential value is available as plaintext

### Requirement: Network credentials are process-local
**ID:** `network-credentials-process-local`
Network automation SHALL expose decrypted credentials and state-encryption input only to the bounded consumer process or its private volatile credential file.

#### Scenario: Automation process exits
**ID:** `runtime-secret-is-removed`
- **WHEN** an OpenTofu or Ansible network operation succeeds, fails, or is interrupted
- **THEN** its decrypted environment or temporary credential file is no longer available to subsequent operations

### Requirement: Network recipients are explicit
**ID:** `network-secret-recipient-set`
The network credential document SHALL be decryptable only by the declared operator custody recipients.

#### Scenario: Undeclared identity attempts decryption
**ID:** `undeclared-recipient-is-rejected`
- **WHEN** an age identity outside the declared recipient set attempts to decrypt the network document
- **THEN** decryption fails without revealing managed values
