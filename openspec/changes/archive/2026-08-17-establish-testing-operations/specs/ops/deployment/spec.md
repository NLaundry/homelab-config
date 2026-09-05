---
id: ops.deployment
---

## Purpose

The repository provides explicit remote deployment operations so an operator can choose build, preview, activation, and persistence behavior without changing the deployment mechanism.

## ADDED Requirements

### Requirement: Deployment defines distinct lifecycle operations
**ID:** `deployment-operation-set`
The repository SHALL define `deploy` as immediate activation that also becomes the boot default, `boot` as the next-boot default without immediate activation, `try` as immediate activation without bootloader persistence, `dry` as a preview without activation, and `build` as a build without activation.

#### Scenario: An operator selects immediate activation
**ID:** `activation-mode-selected`
- **WHEN** an operator selects `deploy` or `try`
- **THEN** the deployment activates immediately
- **AND** only `deploy` persists the generation as the boot default

#### Scenario: An operator avoids immediate activation
**ID:** `non-activation-mode-selected`
- **WHEN** an operator selects `boot`, `dry`, or `build`
- **THEN** the deployment performs the selected next-boot, preview, or build-only action without immediate activation

### Requirement: Immediate activation is verified
**ID:** `post-activation-verification`
The `deploy` and `try` operations SHALL run the default deployed verification suite after successful activation, while operations that do not activate immediately SHALL NOT run deployed verification.

#### Scenario: Immediate activation succeeds
**ID:** `successful-activation-verified`
- **WHEN** `deploy` or `try` activates a generation successfully
- **THEN** deployed verification runs afterwards

#### Scenario: Activation does not complete
**ID:** `failed-activation-not-verified`
- **WHEN** immediate activation fails
- **THEN** deployed verification does not run

### Requirement: Post-activation verification failure is explicit
**ID:** `post-activation-failure-semantics`
An immediate activation operation SHALL return a non-zero status when its post-activation verification fails and SHALL report that activation succeeded without automatic rollback.

#### Scenario: Verification rejects an activated generation
**ID:** `activated-generation-fails-verification`
- **WHEN** activation succeeds and the default deployed verification suite fails
- **THEN** the activation operation fails
- **AND** the operator is told that no rollback was attempted

### Requirement: Deployment inputs are overridable
**ID:** `deployment-inputs-overridable`
The deployment operations SHALL accept overridable `HOST`, `TARGET`, and `FLAKE` inputs so an operator can select the configuration and remote host without editing repository files.

#### Scenario: An operator selects another deployment destination
**ID:** `deployment-input-override-applied`
- **WHEN** an operator supplies alternate `HOST`, `TARGET`, or `FLAKE` values
- **THEN** the selected deployment operation uses those values

## REMOVED Requirements

### Requirement: The Makefile exposes the deploy target surface
**ID:** `makefile-target-surface`

**Reason:** Ownership of the repository-wide Make interface is promoted to `ops.repository-operations`, while this pair retains only deployment operations and their semantics.

**Migration:** Use the `ops.repository-operations` pair's `makefile-operation-surface` requirement for the common Makefile contract. Use `deployment-operation-set` and `deployment-inputs-overridable` for deployment-specific truth.
