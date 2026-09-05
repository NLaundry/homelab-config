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
Network automation SHALL deliver decrypted credentials and state-encryption input only through the selected consumer's child-process environment, without runtime credential files or exports into the operator's interactive shell.

#### Scenario: Automation process exits
**ID:** `runtime-secret-is-removed`
- **WHEN** an OpenTofu or Ansible network operation succeeds, fails, or is interrupted
- **THEN** delivery has not changed the parent shell environment or left a plaintext credential file for subsequent operations

#### Scenario: A consumer scope is selected
**ID:** `consumer-scope-is-exclusive`
- **WHEN** profile `north_york` runs with scope `opentofu` or `opnsense`
- **THEN** the child receives only that scope's declared network inputs, and manifest-declared opposite-scope variables are excluded even if inherited from the parent
- **AND** selecting a scope narrows delivery, not the operator's authority to decrypt the shared document

#### Scenario: Nested fields reach the selected consumer
**ID:** `nested-network-inputs-map-to-consumer`
- **WHEN** the selected scope resolves the nested network document
- **THEN** `opentofu` maps `netbird.pat`, `netbird.management_url`, and `opentofu.state_encryption_passphrase` to `NB_PAT`, `NB_MANAGEMENT_URL`, and `TF_VAR_state_encryption_passphrase`
- **AND** `opnsense` maps `opnsense.url`, `opnsense.api_key`, and `opnsense.api_secret` to `OPNSENSE_URL`, `OPNSENSE_API_KEY`, and `OPNSENSE_API_SECRET`

#### Scenario: A required input is unavailable
**ID:** `missing-network-input-blocks-launch`
- **WHEN** a required file, root object, or leaf field for the selected scope is missing
- **THEN** resolution fails before the consumer launches, without prompting for or generating a live credential and without printing resolved values

### Requirement: Consumer integration precedes live credentials
**ID:** `network-consumer-integration-gate`
Live network credential creation and authentication checks SHALL wait until local scoped delivery checks and both later consumer integrations have been verified with dummy inputs.

#### Scenario: A later consumer is missing
**ID:** `missing-consumer-blocks-live-use`
- **WHEN** the later OpenTofu consumer lacks native state encryption using an ephemeral sensitive input, or the later Ansible consumer lacks direct environment delivery with suppressed logging and pipelining
- **THEN** live credential creation and authentication checks remain blocked rather than being claimed ready

### Requirement: Network recipients are explicit
**ID:** `network-secret-recipient-set`
The network credential document SHALL be decryptable only by the declared operator custody recipients.

#### Scenario: Undeclared identity attempts decryption
**ID:** `undeclared-recipient-is-rejected`
- **WHEN** an age identity outside the declared recipient set attempts to decrypt the network document
- **THEN** decryption fails without revealing managed values
