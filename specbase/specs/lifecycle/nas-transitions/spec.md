---
id: lifecycle.nas-transitions
---

## Purpose

The NAS remains operable through boot and repository-driven deployment transitions, with explicit success, ordering, verification, and failure semantics.

### Requirement: Storage pools become healthy after boot
**ID:** `pools-import-on-boot`
A managed NAS boot SHALL import the declared pre-existing storage pools without forced root import and SHALL leave them online.

#### Scenario: NAS completes a managed boot
**ID:** `pools-online-after-boot`
- **WHEN** the NAS completes a managed boot
- **THEN** both declared pools are imported and report an online state without forced root import

### Requirement: Remote deployment reaches a verified active state
**ID:** `deployment-succeeds`
A remote NAS deployment SHALL build and activate the selected generation on its declared target and SHALL preserve administrator reachability after activation.

#### Scenario: Deployment succeeds end to end
**ID:** `deployment-reaches-verified-state`
- **WHEN** a remote deployment reports success
- **THEN** the selected generation is active and the NAS remains reachable for post-deploy verification

### Requirement: Deployment modes preserve their transition semantics
**ID:** `deployment-operation-set`
The deployment interface SHALL preserve the distinct activation, next-boot, temporary, evaluation-only, and build-only semantics of its declared operations.

#### Scenario: A non-activating operation runs
**ID:** `non-activating-operation-does-not-activate`
- **WHEN** an evaluation-only or build-only operation runs
- **THEN** it does not activate or select a new running generation

#### Scenario: A temporary operation runs
**ID:** `temporary-operation-keeps-rollback-boundary`
- **WHEN** a temporary activation operation succeeds
- **THEN** it does not redefine the persistent boot generation

### Requirement: Verification follows successful activation
**ID:** `post-activation-verification`
An activating deployment operation SHALL run post-activation verification only after activation succeeds.

#### Scenario: Activation fails
**ID:** `failed-activation-skips-verification`
- **WHEN** activation fails
- **THEN** post-activation verification does not run and the deployment fails

### Requirement: Verification failure remains distinguishable from activation failure
**ID:** `post-activation-failure-semantics`
A post-activation verification failure SHALL return failure while reporting that activation completed and SHALL make no unsupported rollback claim.

#### Scenario: Verification fails after activation
**ID:** `verification-failure-is-reported-honestly`
- **WHEN** activation succeeds and post-activation verification fails
- **THEN** the operation returns nonzero and distinguishes the failed verification from activation and rollback state

### Requirement: Post-deploy checks identify the active generation and health
**ID:** `post-deploy-verification`
Post-deploy verification SHALL independently observe administrator reachability, failed system services, and the active system generation and SHALL report any unestablished outcome.

#### Scenario: A deployed service is failed
**ID:** `failed-unit-fails-verification`
- **WHEN** the deployed NAS reports a failed system service
- **THEN** verification fails and retains the failed-unit diagnostic and observed active generation
