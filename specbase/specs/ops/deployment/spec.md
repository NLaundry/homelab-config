---
id: ops.deployment
---

## Purpose
This pair governs the operator-facing deployment machinery that builds on the NAS, activates remotely, and exposes the supported Makefile target surface.

### Requirement: Deploys build on the host and activate remotely as operator
**ID:** `remote-deploy-mechanism`
The repository SHALL provide a deploy mechanism that builds the system on the
target host (not the workstation) and activates it remotely over SSH. The
build SHALL run on the host via `--build-host`, activation SHALL target the
host via `--target-host`, and the deploy SHALL authenticate as the non-root
`operator` user and escalate with passwordless sudo.

#### Scenario: The build runs on the host
**ID:** `build-on-host`
- **WHEN** a deploy is performed
- **THEN** `nixos-rebuild` is invoked with `--build-host` pointed at the NAS
- **AND** the build occurs on the NAS, not on the (macOS/aarch64) workstation

#### Scenario: Activation targets the host as operator
**ID:** `activate-as-operator`
- **WHEN** a deploy is performed
- **THEN** `nixos-rebuild` is invoked with `--target-host operator@10.10.10.11`
- **AND** escalation uses passwordless sudo (not root login)

#### Scenario: An end-to-end deploy succeeds
**ID:** `deploy-succeeds-runtime`
- **WHEN** a deploy is run against the NAS
- **THEN** the system builds on the NAS and activates without error
- **AND** the new generation is reachable over SSH afterwards

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
