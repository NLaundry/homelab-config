## Why

AI services need provider and client credentials, but this repository has no reproducible secret tooling or encrypted runtime-delivery convention. This first stack member establishes that foundation without launching a guest or service.

## What Changes

- Add SOPS, age, SSH-to-age, Nano, and OpenSSH host-key tools to the selected operator environment.
- Create an operator age identity and use NASty's Ed25519 SSH host key as the machine recipient.
- Store only encrypted AI secret material and recipient metadata in the repository.
- Decrypt AI secrets on NASty into volatile runtime state without placing values in Git or the Nix store.

## Planes

### Governance

- `governance.secret-operations`: reproducible encrypted-secret operations and plaintext exclusion (new).

### Configuration

- `configuration.secret-delivery`: selected age recipients and NASty runtime decryption boundary (new).

## Enforcement intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| `secret-tools-available` | test | `tests/tooling/environment.bats` | Supported operator shells resolve every managed secret, editor, and host-key command used by the runbook. |
| `plaintext-secret-exclusion` | test | `tests/secrets/contracts.bats` | Tracked and evaluated inputs contain ciphertext and references rather than secret values. |
| `age-recipient-set`, `host-runtime-decryption` | test | `tests/secrets/contracts.bats` | AI ciphertext structurally targets both recipient classes and decrypts only into volatile host runtime state. |
| `age-recipient-set` | manual | `tests/specbase/manual-verification.md#ai-secret-recipient-provenance` | A sanitized record links the production NASty recipient to its independently observed Ed25519 host-key fingerprint. |

## Impact

- Adds locked `sops-nix` wiring and selected secret tools.
- Adds `.sops.yaml`, encrypted `secrets/ai.yaml`, NASty runtime decryption configuration, and `docs/NAS/ai-secret-bootstrap.md` for the manual custody and credential steps.
- Adds secret contract tests using dummy identities and ciphertext only.
- Does not create the MicroVM or start an AI service.
