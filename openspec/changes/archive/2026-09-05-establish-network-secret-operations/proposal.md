## Why

NetBird and OPNsense automation require long-lived API credentials, but the repository has no applied encrypted-secret workflow and must not place those values in Git, the Nix store, OpenTofu configuration, or command logs. This stack member establishes one shared SOPS convention and an operator runbook before either IaC tool can contact a live control plane.

## What Changes

- Retain the completed SOPS, age, Neovim, and OpenTofu tooling and add SecretSpec 0.20+ with its SOPS provider to the reproducible operator environment; retain Ansible and SSH.
- Establish one repository `.sops.yaml` convention and an encrypted `secrets/network.yaml` document for the NetBird management credential, North York OPNsense API credential, and OpenTofu state-encryption input.
- Add one root `secretspec.toml` that projects the nested SOPS document through root references and JSON extraction into profile `north_york`, with separate `opentofu` and `opnsense` environment scopes. Replace custom wrappers and temporary credential files with SecretSpec scoped child-process delivery.
- Add bounded local OpenTofu state-encryption/provider wiring and an Ansible credential preflight before live credential storage. Full NetBird resource and OPNsense enrollment implementations remain later work.
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
| `secret-tools-available` | manual | `command -v sops age age-keygen nvim tofu ansible ssh secretspec` and `secretspec --version` in each supported Nix development shell | Commands resolve, SecretSpec is 0.20+, and the dummy integration confirms SOPS provider support; not remote authentication. |
| `plaintext-secret-exclusion` | manual | Review of tracked inputs and the runbook | Store only ciphertext and references; do not log or persist resolved values. |
| `single-sops-convention` | manual | Root `.sops.yaml`, `secretspec.toml`, and completed policy evidence | The manifest references the existing network path and root policy; no new recipient convention or cryptography test suite. |
| `network-credentials-process-local` | manual | `evidence/secretspec-validation.md` | One-time dummy verification confirms all six mappings and both scopes. Recheck when mappings or SecretSpec change, not on every build. |
| `operator-secret-recovery` | manual | `docs/operations/network-secret-operations.md#22-back-up-the-identity-in-bitwarden` | An operator retrieves the independently stored identity and confirms that it derives the declared public recipient. |
| `network-credential-rotation` | manual | `docs/operations/network-secret-operations.md#rotate-or-revoke` | The runbook replaces a credential, validates its consumer, and revokes the predecessor without exposing either value. |

## Impact

- Adds shared secret tools and network IaC tools to the flake-managed operator environment.
- Preserves the established root `.sops.yaml` and custody runbook; plans root `secretspec.toml`, encrypted `secrets/network.yaml`, and one-time delivery verification rather than project-owned secret wrappers or recurring upstream-behavior tests.
- Preserves the approved `svc-admin` identity and four subsystem-wide OPNsense ACLs recorded in discovery. Local integration is verified. The `Config Automation` Network Admin service user, `Infra Token`, `svc-admin` OPNsense API key, and encrypted network document exist. This change creates no NetBird network object, plugin change, setup key, or persistent OpenTofu state.
- The completed local wiring and read-only checks do not implement the later NetBird resources or OPNsense enrollment.
- Creates intentional planning overlap with `establish-ai-secret-operations`; that unapplied change must later consume this shared foundation instead of applying a competing one.
