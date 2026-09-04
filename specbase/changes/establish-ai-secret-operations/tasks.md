## 1. Establish reproducible secret operations

- [ ] 1.1 Add locked `sops-nix` input wiring; add `sops`, `age`, `ssh-to-age`, Nano, and OpenSSH's `ssh-keygen`/`ssh-keyscan` to the selected cross-platform operator tool set, catalogue, and `harnessRunner.runtimeInputs`.
- [ ] 1.2 Follow `docs/NAS/ai-secret-bootstrap.md` to generate and back up an operator age identity outside the repository, independently verify and derive NASty's Ed25519 SSH host recipient, and configure `.sops.yaml` without exposing private identities.
- [ ] 1.3 Create encrypted `secrets/ai.yaml` with `OPENROUTER_API_KEY` and `LITELLM_MASTER_KEY` through the runbook's interactive SOPS procedure without exposing values in commands, logs, or evidence.
- [ ] 1.4 Configure NASty to decrypt the AI credentials only into `/run/secrets-rendered/ai.env`, owned by `root:root` with mode `0400`; do not expose the file to a guest in this change.

## 2. Deliver secret-operation evidence

- [ ] 2.1 Extend `tests/tooling/environment.bats` to prove `sops`, `age`, `age-keygen`, `ssh-to-age`, `nano`, `ssh-keygen`, and `ssh-keyscan` resolve on every supported operator system and confirm binding `secret-tool-environment`.
- [ ] 2.2 Implement `tests/secrets/contracts.bats` with generated dummy identities/ciphertext only to reject plaintext inputs, missing recipients, persistent targets, private identities, incorrect owner/group/mode, and store interpolation; register `tests/secrets/*.bats` in the non-live default harness source list; confirm bindings `plaintext-secret-contract` and `host-secret-configuration`.
- [ ] 2.3 Execute both sources through the native Bats/Nix harness; add `tests/specbase/manual-verification.md#ai-secret-recipient-provenance` with the runbook's sanitized fingerprint-to-recipient record; confirm binding `production-recipient-provenance`.
- [ ] 2.4 Add direct requirement observations for the automated bindings, run enforcement-quality with this change's spec root, and validate this change strictly after sources exist.

## 3. Verify rollback

- [ ] 3.1 Exercise the rollback section of `docs/NAS/ai-secret-bootstrap.md`, proving removed runtime configuration leaves ciphertext inert and does not expose or delete operator-owned identities.
