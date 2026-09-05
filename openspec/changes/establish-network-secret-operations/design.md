## Context

The repository already supplies Ansible and general operator tools from `nix/dev.nix`, but it has no applied SOPS policy, encrypted secret document, or OpenTofu executable. The active `establish-ai-secret-operations` change proposes overlapping generic tooling but is unapplied; Stack 1 intentionally establishes the common convention here and leaves that AI change for later reconciliation.

NetBird automation needs a management PAT and management URL. OPNsense automation needs a restricted API key and secret created through a human bootstrap. A later enrollment step also needs a one-use NetBird setup key, but retaining that key in SOPS or OpenTofu state would turn an ephemeral credential into durable secret state.

## Goals / Non-Goals

**Goals:**
- Provide one reproducible SOPS/age workflow for repository-managed secrets.
- Encrypt long-lived NetBird and North York OPNsense credentials plus the OpenTofu state-encryption input at rest.
- Deliver secrets only to bounded OpenTofu and Ansible child processes.
- Give the operator an executable, recovery-aware runbook.
- Prevent setup keys from becoming persistent repository or state data.

**Non-Goals:**
- Create live API credentials automatically.
- Use IaC wrappers to mutate NetBird or OPNsense; the human bootstrap only inspects OPNsense compatibility/ACLs and creates the two restricted automation credentials.
- Configure an OpenTofu backend or create state.
- Enroll a peer or generate a setup key.
- Deliver application or host-runtime secrets.

## Decisions

### One root SOPS policy

Use one repository `.sops.yaml` as the recipient and path policy. `secrets/network.yaml` is the first network document and contains only encrypted values for the NetBird management endpoint/PAT, North York OPNsense API key/secret, and a generated OpenTofu state-encryption passphrase. Future secret families extend this policy rather than adding nested policies.

### Operator-owned decryption

Network IaC runs from the operator environment, so the initial recipient set contains the operator age identity and its documented recovery recipient. No server receives a decryption key in this change. The private identity lives outside the repository at the conventional SOPS age-key path and has an independently stored encrypted backup.

### Bounded consumer adapters

A project-owned command uses `sops exec-env` to expose `NB_PAT` and `NB_MANAGEMENT_URL` only to the OpenTofu child process. The Ansible adapter materializes the OPNsense API credential in a private temporary directory because the selected collection accepts an API credential file; a trap removes the directory on normal exit, error, and interruption. Commands suppress shell tracing and Ansible tasks handling secret material use `no_log`.

The encrypted document uses nested human-readable keys; the adapters perform the environment/file projection so tool-specific variable names do not become the storage schema.

### Deferred setup-key boundary

No setup key field exists in `secrets/network.yaml`, and this member creates no setup key. The enrollment member owns the complete generate-consume-retire transition so every prefix is independently truthful.

### Runbook-first bootstrap

`docs/operations/network-secret-operations.md` is the human boundary. It covers identity creation and backup, obtaining restricted remote credentials without recording them in shell history, initial encryption, dummy decryption checks, recovery, rotation, and revocation. Examples use placeholders or dummy values only.

## Enforcement design

- `tests/tooling/environment.bats` evaluates and builds the development shell on every supported system and fails when `sops`, `age`, `nano`, `tofu`, or retained commands are absent from the current Nix shell. It proves reproducible command availability, not remote authentication.
- `tests/secrets/contracts.bats` runs through the native Bats harness with generated dummy age identities and ciphertext. It checks one root policy, SOPS metadata on the tracked network file, absence of forbidden plaintext-shaped fixture markers, and success/failure cleanup of both consumer adapters. The harness explicitly supplies every command it invokes. It never requires or reads production credentials.
- The recovery drill in `docs/operations/network-secret-operations.md` is manual because custody of an offline identity backup cannot honestly be proven in CI. The operator records sanitized fingerprints and a dummy-ciphertext result; no key or plaintext value enters the evidence.
- The rotation procedure is manual because it crosses live NetBird/OPNsense control planes. Evidence records credential identifiers, timestamps, and successful consumer checks but excludes values.

## Risks / Trade-offs

- [The active AI change also creates SOPS policy] -> Treat this change as the shared foundation and revise the unapplied AI proposal before either overlapping implementation is combined.
- [Environment variables can be inherited by child processes] -> Execute only the intended child, avoid diagnostic environment dumps, and unset at process exit.
- [Temporary OPNsense files can survive abrupt host loss] -> Use a private runtime directory on local volatile storage, mode `0600`, traps, and a pre-run stale-file cleanup check.
- [Static tests can mistake ciphertext for safety] -> Use dummy end-to-end decryption and adapter cleanup tests in addition to structural checks.
- [Losing the operator age key blocks recovery] -> Require an independently stored recovery copy and a dummy recovery drill before live credentials are added.

## Migration Plan

1. Extend the `nix/dev.nix` package list, `tooling.md`, native harness runtime inputs/default Bats list, and focused environment test.
2. Create the operator age identity and recovery backup by following the runbook.
3. Add the root SOPS policy and encrypt a dummy network document first.
4. Implement and test the OpenTofu and Ansible secret adapters with dummy values.
5. Inspect the installed OPNsense version and official plugin/API privilege names through the local GUI, record the least-privilege ACL set, then create the restricted NetBird and OPNsense credentials manually and edit them directly into SOPS.
6. Generate the state-encryption passphrase directly into SOPS and validate both consumer adapters without making IaC configuration changes.
7. Record sanitized credential identifiers, ACL names, and recovery evidence.
8. Reconcile the unapplied AI secret proposal before applying its overlapping tasks.
9. Roll back by revoking live credentials, deleting ciphertext and adapters, and retaining the external age identity only if another secret family uses it.
