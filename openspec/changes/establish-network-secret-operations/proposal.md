## Why

NetBird and OPNsense automation require long-lived API credentials, but the repository has no applied encrypted-secret workflow and must not place those values in Git, the Nix store, OpenTofu configuration, or command logs. This stack member establishes one shared SOPS convention and an operator runbook before either IaC tool can contact a live control plane.

## What Changes

- Extend the existing reproducible operator environment with SOPS, age, Neovim, and OpenTofu while retaining its existing Ansible and SSH tooling.
- Establish one repository `.sops.yaml` convention and an encrypted `secrets/network.yaml` document for the NetBird management credential, North York OPNsense API credential, and OpenTofu state-encryption input.
- Add wrappers that decrypt credentials only into a child process environment or a mode-`0600` temporary file with guaranteed cleanup.
- Add an operator runbook covering age identity creation and backup, restricted OPNsense API-key creation, NetBird PAT creation, encrypted-file editing, validation, rotation, recovery, and revocation.
- Define setup keys as one-use enrollment material that is generated just in time and never committed to encrypted files or retained in OpenTofu state.
- Establish the shared repository secret-operation foundation now; reconcile the overlapping unapplied AI secret proposal later rather than introducing a second SOPS convention.

## Capabilities

### Governance

- `governance.secret-operations`: reproducible SOPS operations, one encrypted-secret convention, and plaintext exclusion across repository-managed credentials (new).

### Configuration

- `configuration.network-secret-delivery`: selected encrypted network credential document, recipients, and process-local delivery boundaries for NetBird and OPNsense automation (new).

### Lifecycle

- `lifecycle.secret-operations`: operator recovery, credential rotation, and revocation procedures preserve access without retaining plaintext repository state (new).

## Verification intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| `secret-tools-available` | manual | `command -v sops age age-keygen nvim tofu ansible ssh` in each supported Nix development shell | Required secret-operation commands resolve; this does not prove remote authentication. |
| `plaintext-secret-exclusion` | test | `tests/secrets/contracts.bats` | Tracked network secret material is SOPS ciphertext and generated OpenTofu/Ansible inputs contain references rather than credential values. |
| `single-sops-convention` | test | `tests/secrets/contracts.bats` | Repository secret paths match one root SOPS policy and no competing tracked recipient policy is introduced. |
| `network-credentials-process-local` | test | `tests/secrets/contracts.bats` | Dummy credentials enter only a bounded child environment or private temporary file and cleanup occurs on success and failure. |
| `operator-secret-recovery` | manual | `docs/operations/network-secret-operations.md#recovery-drill` | An operator restores a test identity from the documented backup and decrypts only dummy ciphertext. |
| `network-credential-rotation` | manual | `docs/operations/network-secret-operations.md#rotate-or-revoke` | The runbook replaces a credential, validates its consumer, and revokes the predecessor without exposing either value. |

## Impact

- Adds shared secret tools and network IaC tools to the flake-managed operator environment.
- Adds `.sops.yaml`, encrypted `secrets/network.yaml`, secret execution wrappers, contract tests, and `docs/operations/network-secret-operations.md`.
- Creates the restricted North York OPNsense automation identity/key and NetBird PAT through the documented human bootstrap, but introduces no live NetBird object, NetBird plugin change, setup key, or OpenTofu state.
- Creates intentional planning overlap with `establish-ai-secret-operations`; that unapplied change must later consume this shared foundation instead of applying a competing one.
