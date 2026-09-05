---
id: governance.secret-operations
---

## Purpose

Repository operators can create and maintain encrypted service secrets through the reproducible project tool environment while plaintext secret material remains outside tracked and evaluated inputs.

## ADDED Requirements

### Requirement: Secret operations are available from the operator environment
**ID:** `secret-tools-available`
The repository SHALL provide the commands required to create operator identities, derive recipients, and edit SOPS-encrypted files through its selected operator tool set on every supported system.

#### Scenario: Operator opens the development shell
**ID:** `secret-commands-resolve`
- **WHEN** an operator enters the default development shell on a supported system
- **THEN** the selected secret-management commands resolve without unmanaged global installations

### Requirement: Plaintext secrets remain outside repository inputs
**ID:** `plaintext-secret-exclusion`
The repository secret workflow SHALL reject plaintext service credentials from tracked files and Nix-evaluated configuration values.

#### Scenario: Secret configuration is checked
**ID:** `plaintext-input-is-rejected`
- **WHEN** repository secret contracts inspect tracked and evaluated inputs
- **THEN** a plaintext credential or private identity causes the check to fail
