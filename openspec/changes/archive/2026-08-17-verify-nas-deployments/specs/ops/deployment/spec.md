---
id: ops.deployment
---

## Purpose

The repository deploys NAS generations remotely and provides evidence that an activated generation remains reachable and operational before the operator treats the deployment as verified.

## ADDED Requirements

### Requirement: Activated deployments receive live verification
**ID:** `post-deploy-verification`
The default live suite invoked after immediate NAS activation SHALL include deployment-health checks. The deployment SHALL be reported as unverified when the NAS is unreachable, a systemd unit is failed, the active system generation is invalid, or a selected deployment check fails.

#### Scenario: The activated NAS passes its deployment smoke checks
**ID:** `active-generation-verified`
- **WHEN** the default `make verify` suite runs after activation
- **THEN** the NAS is reachable over SSH
- **AND** no systemd unit is failed
- **AND** `/run/current-system` resolves to an existing Nix store system generation

#### Scenario: Verification fails after activation
**ID:** `post-deploy-failure-reported`
- **WHEN** any selected deployment check fails
- **THEN** verification exits non-zero and identifies the failed condition
- **AND** it does not claim that the deployment was rolled back
