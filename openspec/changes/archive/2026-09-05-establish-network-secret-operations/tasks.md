## 1. Extend the reproducible operator tool set

- [x] 1.1 Add SOPS, age, Neovim, and OpenTofu to the single `nix/dev.nix` package list; retain Ansible and SSH.
- [x] 1.3 Build and enter each supported operator environment available to CI and record the commands and results in change progress.

## 2. Establish the shared SOPS policy and custody runbook

- [x] 2.1 Write `docs/operations/network-secret-operations.md` with bootstrap, external age-key custody, recovery verification, restricted NetBird and OPNsense credential creation, encrypted editing, rotation, revocation, and sanitized evidence instructions.
- [x] 2.2 Generate the operator age identity and independently held recovery material by following the runbook; record only public recipient fingerprints.
- [x] 2.3 Add one root `.sops.yaml` policy for managed secret paths and prove its recipient selection with dummy ciphertext before introducing live values.
- [x] 2.4 Through the local OPNsense GUI, record the installed version and official plugin/API privilege names, define the least-privilege automation ACL set, and stop if it cannot be bounded.
- [x] 2.5 Use the existing `Config Automation` Network Admin `Infra Token` and create the `svc-admin` OPNsense API key after the completed local wiring check. Create nested `secrets/network.yaml` directly through SOPS with those values plus a generated OpenTofu state-encryption passphrase; verify Git, shell history, and captured output contain no plaintext values.

## 3. Implement SecretSpec scoped delivery

- [x] 3.1 Add SecretSpec 0.20+ with the SOPS provider to the reproducible operator package set; evaluate both supported shells, verify `secretspec --version` on the available operator platform, and confirm provider availability with the one-time dummy integration in Task 4.1.
- [x] 3.2 Add root `secretspec.toml` using the SOPS provider for `secrets/network.yaml` and the existing root `.sops.yaml`, profile `north_york`, root-item references plus JSON extraction, and required inputs without prompts, generation, plaintext defaults, or file delivery; verify all six mappings against the design using dummy values.
- [x] 3.3 Define scope `opentofu` for `NB_PAT`, `NB_MANAGEMENT_URL`, and `TF_VAR_state_encryption_passphrase`, and scope `opnsense` for `OPNSENSE_URL`, `OPNSENSE_API_KEY`, and `OPNSENSE_API_SECRET`; verify explicit `run --profile north_york --scope ...` child delivery and opposite-scope exclusion. Use SecretSpec directly, not custom adapters or temporary credential files.

### Local consumer wiring

The following local credential wiring is implemented and verified once with dummy values:

- `infra/netbird` consumes `NB_PAT`, `NB_MANAGEMENT_URL`, and an ephemeral sensitive state-encryption passphrase; it enforces native state and plan encryption and declares no resources.
- The Ansible credential preflight reads `OPNSENSE_URL`, `OPNSENSE_API_KEY`, and `OPNSENSE_API_SECRET` through direct module defaults with `no_log`, pipelining, and no credential file. It makes no API request.

Full later resource and enrollment implementations remain pending. Keep Task 5.1 unchecked until bounded read-only authentication entry points exist; do not substitute a live apply or enrollment operation.

## 4. Record one-time delivery verification

- [x] 4.1 Confirm all six nested-field mappings and both SecretSpec scopes once with isolated dummy SOPS data. Record the result without retaining a recurring test suite for upstream behavior. Recheck when mappings or SecretSpec change; retain completed custody/policy evidence.

## 5. Validate the foundation

- [x] 5.1 After Task 2.5 and bounded read-only authentication entry points are complete, launch each through the matching SecretSpec scope; verify successful authentication without credential output or remote mutation. Do not substitute an apply or enrollment operation.
- [x] 5.2 Run `make check` for Nix evaluation and separately run `openspec validate establish-network-secret-operations --strict`; record local results separately from the blocked live tasks. Later members may supply local consumer integration without claiming this member's live validation complete. `make check` does not run OpenSpec or shell tests.
- [x] 5.3 Mark the unapplied `establish-ai-secret-operations` plan for later reconciliation with this shared foundation; do not implement a second `.sops.yaml` or operator identity convention.
