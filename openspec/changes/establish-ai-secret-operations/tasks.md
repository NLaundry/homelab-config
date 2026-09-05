This plan is deferred until it is reconciled with the network secret foundation.
The former `docs/NAS/ai-secret-bootstrap.md` was removed; prepare a current
runbook before any credential operation, and reuse the shared SOPS policy and
operator identity rather than creating a second convention.

## 1. Establish reproducible secret operations

- [ ] 1.1 Add locked `sops-nix` input wiring; add `sops`, `age`, `ssh-to-age`, Nano, and OpenSSH's `ssh-keygen`/`ssh-keyscan` to the selected cross-platform operator tool set.
- [ ] 1.2 Follow `docs/NAS/ai-secret-bootstrap.md` to generate and back up an operator age identity outside the repository, independently verify and derive NASty's Ed25519 SSH host recipient, and configure `.sops.yaml` without exposing private identities.
- [ ] 1.3 Create encrypted `secrets/ai.yaml` with `OPENROUTER_API_KEY` and `LITELLM_MASTER_KEY` through the runbook's interactive SOPS procedure without exposing values in commands, logs, or evidence.
- [ ] 1.4 Configure NASty to decrypt the AI credentials only into `/run/secrets-rendered/ai.env`, owned by `root:root` with mode `0400`; do not expose the file to a guest in this change.

## 2. Deliver secret-operation evidence

- [ ] 2.1 Manually run `command -v sops age age-keygen ssh-to-age nano ssh-keygen ssh-keyscan` in each supported Nix development shell before following the secret runbook; stop if a required command is missing.
- [ ] 2.2 Implement `tests/secrets/contracts.bats` with generated dummy identities/ciphertext only to reject plaintext inputs, missing recipients, persistent targets, private identities, incorrect owner/group/mode, and store interpolation.
- [ ] 2.3 Run `bats tests/secrets/contracts.bats` in the Nix development shell and record results; retain the sanitized production fingerprint-to-recipient record with the procedure in `docs/NAS/ai-secret-bootstrap.md`.
- [ ] 2.4 Run `make check` for Nix evaluation and separately run `openspec validate establish-ai-secret-operations --strict` after sources exist. `make check` does not run OpenSpec or shell tests.

## 3. Verify rollback

- [ ] 3.1 Exercise the rollback section of `docs/NAS/ai-secret-bootstrap.md`, proving removed runtime configuration leaves ciphertext inert and does not expose or delete operator-owned identities.
