## Context

See `proposal.md` for motivation. SOPS, age, Neovim, and OpenTofu tooling, operator identity custody with a Bitwarden attachment backup, the root `.sops.yaml`, and OPNsense ACL discovery are recorded as complete. Preserve those decisions and their evidence.

SecretSpec 0.20.0, root `secretspec.toml`, encrypted `secrets/network.yaml`, local `infra/netbird` credential/encryption wiring, and an Ansible credential preflight are implemented. One-time dummy delivery and bounded live authentication both passed. NetBird resources and OPNsense enrollment remain later work.

The unapplied `establish-ai-secret-operations` change overlaps the generic tooling. It must later consume this shared convention rather than introduce another SOPS policy.

## Goals / Non-Goals

**Goals:**
- Keep long-lived network credentials and the OpenTofu state-encryption input encrypted under one root SOPS policy.
- Use SecretSpec 0.20+ with its SOPS provider for scoped child-process environment delivery, preserving nested storage keys.
- Verify local mapping and consumer integration before creating or checking live credentials.
- Preserve operator-owned recovery and the one-use setup-key boundary.

**Non-Goals:**
- Write custom decryption adapters, runtime credential files, or shell export/eval pipelines.
- Create live API credentials automatically or mutate network configuration.
- Implement NetBird resources, OPNsense mutation tasks, or the later enrollment operation.
- Configure a backend, create state, enroll peers, generate setup keys, or deliver host-runtime secrets.

## Decisions

### Preserve one root policy and nested storage

Keep `.sops.yaml` as the sole recipient/path policy and `secrets/network.yaml` as the selected encrypted document. Retain root objects `netbird`, `opnsense`, and `opentofu`; do not flatten them into environment variable names or wrap them in a SecretSpec project/profile namespace. No setup-key field belongs in the document.

The operator age identity stays outside Git and the Nix store at the conventional SOPS location, or is selected by `SOPS_AGE_KEY_FILE` containing only its path. Its independently held recovery copy is an encrypted attachment on a dedicated Bitwarden item. A backup of the same identity does not require a second recipient. No server receives a decryption identity.

### SecretSpec replaces project-owned adapters

Add SecretSpec 0.20+ with the SOPS provider to the reproducible package set. Declare root `secretspec.toml` with a single-file provider alias pointing to `sops://secrets/network.yaml?sops_config=.sops.yaml` and profile `north_york`. Relative provider and policy paths resolve from the manifest directory.

Use a SOPS root-item `ref` and `extract = { format = "json", pointer = "..." }` per value. The provider returns a selected object as JSON; extraction selects its leaf. Do not use dotted item names or `ref.field`, which are not nested SOPS selectors. The intended mapping is:

| Scope | Child variable | Root `ref.item` | JSON pointer | Stored field |
|---|---|---|---|---|
| `opentofu` | `NB_PAT` | `netbird` | `/pat` | `netbird.pat` |
| `opentofu` | `NB_MANAGEMENT_URL` | `netbird` | `/management_url` | `netbird.management_url` |
| `opentofu` | `TF_VAR_state_encryption_passphrase` | `opentofu` | `/state_encryption_passphrase` | `opentofu.state_encryption_passphrase` |
| `opnsense` | `OPNSENSE_URL` | `opnsense` | `/url` | `opnsense.url` |
| `opnsense` | `OPNSENSE_API_KEY` | `opnsense` | `/api_key` | `opnsense.api_key` |
| `opnsense` | `OPNSENSE_API_SECRET` | `opnsense` | `/api_secret` | `opnsense.api_secret` |

For example, a future manifest declaration for `NB_PAT` uses `ref = { item = "netbird" }` and `extract = { format = "json", pointer = "/pat" }`, with the SOPS alias selected as provider. All six inputs are required. Do not provide plaintext defaults, environment fallback providers, prompts, automatic generation, `as_path`, or cached plaintext. Continue editing the nested document through SOPS, not through SecretSpec convention-addressed writes.

Define `[scopes.opentofu]` and `[scopes.opnsense]` with `secrets` allowlists matching the table. Always pass both `--profile north_york` and the intended nonempty `--scope` to `secretspec run`. An unscoped run would deliver the whole profile. Scoped runs remove manifest-declared opposite-scope variables from the child even if inherited from the parent; they do not clear arbitrary unrelated environment variables.

This uses the upstream tool instead of maintaining custom decryption, projection, temporary-file cleanup, and interruption logic. No decrypted OPNsense credential file is created for delivery. Do not export resolved values into the interactive shell or use environment dumps, tracing, or verbose secret diagnostics.

### Local consumer wiring is bounded

`infra/netbird` reads provider authentication from `NB_PAT` and `NB_MANAGEMENT_URL`. It declares `state_encryption_passphrase` as an ephemeral, sensitive input and connects it to enforced native state and plan encryption. The provider and both supported platforms are locked. The root declares no NetBird resources, and no real backend or state was initialized.

The local Ansible credential preflight uses play-level `module_defaults` with direct environment lookups for `OPNSENSE_URL`, `OPNSENSE_API_KEY`, and `OPNSENSE_API_SECRET`. It uses `no_log`, pipelining, and HTTPS verification, creates no credential file, and makes no API request. The OPNsense collection is pinned to an immutable source revision.

Both paths passed one-time local validation through their SecretSpec scopes with dummy values. The NetBird provider then read account settings and Ansible read the OPNsense NetBird status endpoint with no remote mutation or credential output. Do not substitute apply, enrollment, or environment dumps for these bounded checks.

### Approved OPNsense permissions

The discovery evidence records OPNsense `26.7.3`, official `os-netbird` installed, group `netbird-automation`, and user `svc-admin` with scrambled password login, only that group, and no direct privileges, shell access, SSH keys, `admins`, or `All pages` access. Its four approved ACLs are:

- `VPN: NetBird`
- `Interfaces: Assign network ports`
- `Firewall: Alias: Edit`
- `Firewall: Rules [new]`

These ACLs grant subsystem-wide operations, not object-only access to North York NetBird resources. The approved boundary excludes firmware and configuration-backup access; automation configuration must still limit the objects it changes. Recheck effective privileges before key creation rather than recreating this completed discovery blocker.

The upstream revisions recorded in `evidence/opnsense-inspection.md` support ACL research; they are not exact installed-code pins for the observed release. Later consumer integration must verify its actual module/API needs against the installed system without silently widening permissions.

### Runbook-first custody and setup-key boundary

The runbook covers external key custody, direct SOPS editing, restricted human credential creation after local verification, recovery, rotation, and revocation. Examples contain no live secret values. No setup key is retained in SOPS or OpenTofu state; the later enrollment member owns generate-consume-retire as one transition.

## Verification design

- In supported Nix shells, run `command -v sops age age-keygen nvim tofu ansible ssh secretspec` and `secretspec --version`; require 0.20+ and confirm SOPS provider support with the dummy integration.
- Record a one-time integration check using isolated dummy encrypted data, never the live document or production credentials. Confirm all six nested-field mappings and both scope selections without printing values. Recheck when mappings or SecretSpec change. Do not retain a recurring suite for behavior supplied by SecretSpec or SOPS.
- Do not build tests that retest SOPS/age cryptography, recipient rejection, or Bitwarden backup behavior. Preserve the completed policy/custody evidence; review that the manifest still points to the existing policy and nested document.
- The operator manually verifies recovery by retrieving the Bitwarden attachment and comparing its derived public recipient. Record no private material. This is custody verification, not a backup-product test suite.
- Later consumer integration and live rotation checks remain separate prerequisites and manual operations. Evidence contains identifiers, dates, privileges, and results only.

## Risks / Trade-offs

- [A scope is delivery minimization, not an authorization boundary] -> The SOPS provider can decrypt the shared document, and a child with custody access can resolve another scope. Trust and isolate the operator process; never claim per-scope encryption or hostile-process isolation.
- [Environment values can leak through descendants, logs, or diagnostics] -> Run only the intended consumer with an explicit scope; disable tracing/debug output, use Ansible `no_log` and pipelining, and do not persist credentials.
- [A passphrase variable alone does not encrypt OpenTofu state] -> Block live credentials/checks until the later native encryption configuration and ephemeral/sensitive input are locally verified.
- [ACLs are broader than managed objects and source research is not an installed-code pin] -> Preserve the four approved subsystem ACLs, verify effective privileges and actual API needs, and stop rather than silently broadening access.
- [Losing the operator age identity blocks recovery] -> Keep the independent encrypted Bitwarden attachment and verify its public recipient before live credential creation.
- [The unapplied AI proposal overlaps policy] -> Reconcile it later against this shared foundation.

## Migration Plan

1. Preserve completed tooling, custody, root policy, and ACL evidence.
2. Add SecretSpec 0.20+ with SOPS support, root manifest, and scoped environment delivery; test only with dummy inputs.
3. Verify local OpenTofu and Ansible credential wiring with dummy inputs.
4. Recheck approved effective permissions, then create remote credentials manually and enter them plus the state-encryption passphrase directly through SOPS.
5. Run each bounded read-only authentication entry point under its matching scope; record sanitized outcomes, not values. This creates no network configuration or persistent state.
6. Reconcile the unapplied AI proposal before its overlapping implementation.
7. For rollback, revoke any live credentials before removing the network ciphertext and SecretSpec declarations. Retain shared policy/tools and external custody when another secret family uses them; never assume local deletion revokes remote access.

## References

- [SecretSpec SOPS provider](https://secretspec.dev/providers/sops/)
- [SecretSpec configuration and extraction](https://secretspec.dev/reference/configuration/)
- [SecretSpec scopes](https://secretspec.dev/concepts/scopes/)
- [Recorded OPNsense inspection](evidence/opnsense-inspection.md)
