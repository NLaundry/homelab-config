## 1. Extend the reproducible operator tool set

- [x] 1.1 Add SOPS, age, Nano, and OpenTofu to the single `nix/dev.nix` package list; retain Ansible and SSH.
- [x] 1.3 Build and enter each supported operator environment available to CI and record the commands and results in change progress.

## 2. Establish the shared SOPS policy and custody runbook

- [x] 2.1 Write `docs/operations/network-secret-operations.md` with bootstrap, external age-key custody, recovery drill, restricted NetBird and OPNsense credential creation, encrypted editing, rotation, revocation, and sanitized evidence instructions.
- [ ] 2.2 Generate the operator age identity and independently held recovery material by following the runbook; record only public recipient fingerprints.
- [ ] 2.3 Add one root `.sops.yaml` policy for managed secret paths and prove its recipient selection with dummy ciphertext before introducing live values.
- [ ] 2.4 Through the local OPNsense GUI, record the installed version and official plugin/API privilege names, define the least-privilege automation ACL set, and stop if it cannot be bounded.
- [ ] 2.5 Create the restricted NetBird PAT and OPNsense automation key only after Task 2.4, then create `secrets/network.yaml` directly through SOPS with those values plus a generated OpenTofu state-encryption passphrase; verify Git, shell history, and captured output contain no plaintext values.

## 3. Implement bounded consumer delivery

- [ ] 3.1 Add a project-owned OpenTofu adapter that maps decrypted network fields to `NB_MANAGEMENT_URL`, `NB_PAT`, and the process-local OpenTofu state-encryption configuration only for the child process.
- [ ] 3.2 Add a project-owned Ansible adapter that writes the selected OPNsense credential format to a mode-`0600` private volatile file, suppresses secret logging, and removes the file on success, failure, and interruption.
- [ ] 3.3 Add pre-run checks that reject missing ciphertext, undeclared recipients, unsafe temporary paths, shell tracing, and stale decrypted files.

## 4. Deliver secret contract evidence

- [ ] 4.1 Implement `tests/secrets/contracts.bats` with generated dummy identities and ciphertext to verify the single root policy, ciphertext-at-rest, recipient rejection, process-local delivery, cleanup behavior, and absence of persistent setup-key fields/resources; run `bats tests/secrets/contracts.bats` in the Nix development shell and record the command and result.
- [ ] 4.4 Perform and record the runbook recovery drill with dummy ciphertext; retain no private identity or decrypted value in the evidence.

## 5. Validate the foundation

- [ ] 5.1 Validate that the encrypted network document can launch bounded read-only NetBird and OPNsense authentication checks without printing credentials or changing remote state.
- [ ] 5.2 Run `make check` for Nix evaluation and separately run `openspec validate establish-network-secret-operations --strict`; record the results before the next stack member. `make check` does not run OpenSpec or shell tests.
- [ ] 5.3 Mark the unapplied `establish-ai-secret-operations` plan for later reconciliation with this shared foundation; do not implement a second `.sops.yaml` or operator identity convention.
