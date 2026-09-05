## Context

The repository currently has no SOPS configuration, age identity convention, encrypted secret file, or selected SOPS/age tools. AI provider and gateway credentials must be available before services start, but values must not enter Git, Nix evaluation, the store, logs, or evidence.

## Goals / Non-Goals

**Goals:**

- Give operators a reproducible encrypted-secret workflow.
- Establish operator and NASty recipients.
- Render AI credentials only into volatile NASty runtime state.
- Prove the workflow using dummy identities and ciphertext.

**Non-Goals:**

- Guest secret mounting, MicroVM creation, service startup, secret rotation automation, or backup automation.

## Decisions

- Add `sops`, `age`, `ssh-to-age`, Neovim, and OpenSSH's host-key tools to the existing selected tool set rather than requiring global installations.
- Use one operator-controlled age identity for editing/recovery and NASty's persistent Ed25519 SSH host identity for deployment decryption.
- Keep ciphertext in `secrets/ai.yaml` and public recipient metadata in Git; keep both private identities out of the repository. Follow `docs/NAS/ai-secret-bootstrap.md` for identity backup, host-key verification, interactive credential entry, deployment checks, rotation, and rollback.
- Use sops-nix to render `/run/secrets-rendered/ai.env` on NASty, owned by `root:root` with mode `0400`. Later stack members may consume service-specific views, but this member does not expose it to a guest.
- Fail dependent configuration when recipient metadata, output path, ownership, or mode is unsafe.

## Verification design

### Manual shell availability check

- In each supported Nix development shell, run `command -v sops age age-keygen ssh-to-age nvim ssh-keygen ssh-keyscan` before following the secret runbook.
- Stop if a required command is missing; no tool-inventory test is required.
- This checks availability, not safe handling.

### `tests/secrets/contracts.bats`

- Run `bats tests/secrets/contracts.bats` in the Nix development shell with generated dummy identities and ciphertext only.
- Assert both recipient classes exist, decryption targets are volatile, and tracked/evaluated inputs contain no plaintext or private identity.
- Fail on plaintext markers, missing recipients, persistent targets, store interpolation, or unsafe mode.
- This cannot prove private-key backup, production recipient provenance, or absence of host compromise.

### Production recipient provenance in `docs/NAS/ai-secret-bootstrap.md`

- Record the independently observed NASty Ed25519 fingerprint and its derived public age recipient with revision, generation, persona, UTC time, freshness, limitations, blast radius, and cleanup/result.
- Never record a private identity or credential value.
- Treat the record as stale after host-key, recipient-policy, or active-generation change.

## Risks / Trade-offs

- **[Operator identity is lost]** -> Require an operator-controlled recovery recipient and document off-repository backup as an evidence boundary.
- **[NASty SSH key rotates]** -> Update SOPS recipients before rotation; do not remove the old recipient until re-encryption succeeds.
- **[Tests touch production material]** -> Generate dummy fixtures and reject production secret paths in the secret-contract checks.

## Migration Plan

1. Add tools and tests before creating real ciphertext.
2. Generate the operator identity outside Git and derive the NASty public recipient.
3. Add recipient policy and encrypted AI keys without exposing values to commands or evidence.
4. Enable volatile host decryption and run contracts.
5. Rollback removes runtime configuration while leaving ciphertext inert and operator identities untouched.
