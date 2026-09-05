---
id: governance.secret-operations
---

## Purpose

Repository secret operations provide one reproducible encrypted workflow while excluding plaintext credentials from tracked and evaluated inputs.

## ADDED Requirements

### Requirement: Secret tools are reproducible
**ID:** `secret-tools-available`
The supported operator environments SHALL provide every secret-management command named by the repository runbook.

#### Scenario: Operator enters a supported environment
**ID:** `operator-tools-resolve`
- **WHEN** an operator enters a supported repository environment
- **THEN** each managed encryption, identity, and secret-execution command resolves from the repository tool set

### Requirement: Plaintext secrets are excluded
**ID:** `plaintext-secret-exclusion`
The repository SHALL exclude plaintext managed credentials from tracked files and evaluated build inputs.

#### Scenario: Repository inputs are inspected
**ID:** `repository-inputs-contain-no-plaintext`
- **WHEN** tracked files and evaluated inputs are checked
- **THEN** managed credential material is represented only by ciphertext, references, or dummy test values

### Requirement: Secret policy is singular
**ID:** `single-sops-convention`
The repository SHALL govern managed encrypted documents through one root secret policy.

#### Scenario: A managed secret document is added
**ID:** `managed-document-uses-root-policy`
- **WHEN** a managed encrypted document is introduced
- **THEN** its path and recipients are resolved by the repository root policy without a competing nested policy
