---
id: configuration.secret-delivery
---

## Purpose

AI service credentials use a selected SOPS/age recipient set and decrypt on NASty only into volatile runtime state.

## ADDED Requirements

### Requirement: AI secrets target the selected recipient set
**ID:** `age-recipient-set`
The encrypted AI secret document SHALL target one operator-controlled age recipient and NASty's Ed25519 SSH host recipient.

#### Scenario: Encrypted AI secrets are inspected
**ID:** `required-recipients-are-present`
- **WHEN** recipient metadata for the AI secret document is evaluated
- **THEN** both the operator and NASty recipients are present

### Requirement: NASty decrypts secrets into runtime state
**ID:** `host-runtime-decryption`
NASty SHALL render decrypted AI service credentials only at `/run/secrets-rendered/ai.env` with owner `root`, group `root`, and mode `0400`.

#### Scenario: NASty configuration is evaluated
**ID:** `decryption-target-is-volatile`
- **WHEN** the SOPS configuration is evaluated
- **THEN** the decrypted AI credential target is `/run/secrets-rendered/ai.env`, outside the Nix store and persistent repository paths, with the selected owner, group, and mode
