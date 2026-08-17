## Context

The NAS currently exposes guest-writable SMB shares whose file operations are forced to the human `operator` identity. A live write test against those shares would therefore possess the same filesystem authority as the operator and would be difficult to distinguish from human activity in service logs. A newly valid Samba tester account would also inherit access to those shares unless they explicitly deny it. The repository has no implemented secret-management platform; credentials are currently operator-managed.

The planned Samba enforcement change needs honest separation between two kinds of evidence. Disposable VM tests can prove the production guest-write configuration against temporary storage. Deployed checks can verify discovery, listing, mounting, and reading on the real shares without mutation. Any deployed write transaction instead uses an authenticated testing principal and a state boundary that contains mistakes and leaves an attributable audit trail.

## Goals / Non-Goals

**Goals:**

- Establish a remote `tester` principal distinct from operators and future deployment identities.
- Deny that principal access to ordinary shares while preserving their guest behavior.
- Give the tester one authenticated, non-browseable SMB endpoint backed only by bounded test state.
- Associate every repository-driven mutation with a collision-resistant run namespace and auditable path.
- Keep tester credentials outside Git, Nix derivations, process arguments, and captured test output.
- Provide explicit principal/credential lifecycle, audit observation, and exact residual-state recovery procedures.

**Non-Goals:**

- Add `tester-admin` before a concrete privileged operation exists.
- Sandbox every local process in the operator environment; this change limits authority accepted by the remote verification endpoint.
- Grant the tester sudo, deployment, reboot, pool-management, SSH, or ordinary-share authority.
- Replace the guest access policy on `mediaBin` or `smolBoy`.
- Claim that the restricted live endpoint proves `guest-force-operator`; disposable VM evidence owns that claim.
- Introduce a general secrets platform or in-house deployment pipeline.

## Decisions

### Model tester as a remote role with protocol-specific principals

The durable architecture names the tester role and the authority accepted by remote homelab boundaries. The initial Ops realization uses a locked, non-login Unix account plus an authenticated Samba passdb principal with the same operational identity. The local Bats process may still run from the operator workstation, but its verification SMB credential cannot be used for SSH, sudo, deployment, or ordinary-data access.

`tester-admin` remains absent. Until a privileged verification operation is justified, a human operator performs exceptional session revocation, audit inspection, and residue recovery through narrow runbooks.

### Explicitly deny tester on ordinary shares

The normal shares retain their existing guest access and force-user semantics, but add an explicit tester denial. This prevents a valid tester session from being forced to the `operator` filesystem identity. The verification endpoint must not inherit or declare `force user = operator`.

This changes selected Samba realization without changing the normal client-visible guest contract.

### Use a dedicated hidden SMB endpoint

The initial endpoint is a non-browseable share such as `homelab-verification$`, rooted at dedicated state such as `/var/lib/homelab-verification/smb`. Non-browseability is only presentation: authorization requires the tester principal and rejects clients without its current credential.

The root has an operator-owned parent, a fixed child layout, and no ordinary data. The tester receives only the minimum write authority needed beneath run namespaces and cannot alter root metadata. Samba wide-link behavior is disabled, symlink traversal is rejected, and state is backed by a size/inode-bounded filesystem, dataset, or equivalent enforced quota so a compromised credential cannot exhaust the NAS root filesystem.

### Use cooperative run isolation, not per-run authorization

All runs share one tester principal, so run names do not create adversarial authorization boundaries. Each invocation generates a collision-resistant run ID, exclusively creates one direct child namespace, and records that identity for all subsequent operations. Repository helpers accept a run ID rather than an arbitrary path, construct the path beneath the fixed root, reject duplicates and traversal, and remove only that exact namespace.

This prevents accidental collisions and broad cleanup while remaining honest that another holder of the same tester credential could address an existing run namespace. Per-run principals or ACLs would require a privileged broker and are deferred.

### Select an operator-managed Samba passdb lifecycle

The initial server-side principal is provisioned and retired through a runbook using Samba passdb administration with secret delivery over standard input and shell tracing disabled. The procedure verifies passdb ownership and persistence across ordinary deployments. The matching client credential lives in an operator-only directory as a mode-`0600` regular file that is rejected if it is a symlink; it is read through the SMB client's authentication-file facility rather than exported or placed in arguments.

Rotation blocks new tester connections, terminates existing tester sessions, replaces the passdb secret, confirms the previous credential cannot open a new session, and confirms the replacement can. Retirement follows the same revocation order before removing the principal.

A future in-house pipeline may replace secret materialization through an Ops-only change. An explicitly invoked live check assumes home-network reachability and valid credentials; absence or failure is non-zero rather than a green skip.

### Make audit observation an operator action

The verification share enables Samba mutation auditing for namespace creation, file creation/write, rename, unlink, and directory removal. Records go to operator-readable, tester-nonwritable system logs and include the authenticated principal, client, share, operation, and affected path. Because the tester must not receive log-reading authority, the live mutation test does not retrieve its own audit records.

A separate operator procedure queries a bounded execution window and run ID, verifies the expected records, and preserves enough context to discover residue if the client dies before reporting it.

### Keep guest-write evidence separate

The restricted transaction proves the deployed verification endpoint, tester identity, audit path, and cleanup boundary. It is not bound to normal Samba guest-write requirements. The Samba capability change keeps its client/server VM transaction as evidence for guest writes and makes deployed normal-share checks non-mutating.

## Enforcement design

### Live SMB fixture transaction

`tests/verify/smb-fixtures.bats` runs through the packaged live-verification entry point from the home deployment environment. It reads the protected authentication file, confirms guest and invalid-current-credential access fail, creates an exclusive run namespace, writes and reads unique content, removes the namespace, and confirms absence. Any authentication, transport, assertion, or cleanup failure is non-zero and identifies the run. A controlled cleanup failure must report the exact namespace before manual recovery. This source proves the endpoint contract, not normal guest-share writes or resilience after client host loss.

### Live audit observation

`tests/specbase/manual-verification.md#live-verification-audit` gives an operator a bounded run-ID/time-window query against deployed Samba audit records. It confirms principal, client, share, operation, and path for the controlled live transaction. It proves deployed attribution without giving the tester operator log authority.

### Verification identity boundary conformance

`tests/harness/verification-identity-boundary.bats` evaluates the candidate NAS configuration and exercises controlled path fixtures. It asserts that the tester is distinct from operator/deployment identities, lacks interactive and administrative authority, is denied by ordinary shares, and that accepted verification paths resolve beneath bounded dedicated state. Controlled traversal, symlink, collision, cross-run-helper, broad-deletion, and capacity configurations must be rejected. It proves declared structure and helper containment, not isolation from a malicious holder of the same credential or deployed filesystem drift.

### Runtime capacity exercise

`tests/verify/profiles/smb-fixture-capacity.bats` runs as a separate, explicitly selected live profile. It uses separate freshly cleaned run namespaces for the byte and inode phases: one fills bounded-size files until the byte limit rejects further allocation, and the other creates bounded-count empty files until the inode limit rejects further allocation. During exhaustion it confirms an ordinary share remains independently listable, then removes the exact run namespace and reports any residue. The profile has its own overall byte, file-count, and time ceilings so a misconfigured limit cannot consume unbounded space. It proves the deployed capacity failure boundary at execution time; it does not prove future availability or protect against a malicious client that ignores the repository runner.

### Identity operations conformance

`tests/harness/verification-identity-operations.bats` evaluates the Unix account and inspects controlled secret-input expansion. It fails if the tester gains login/sudo/SSH/deployment privileges or if credential values enter repository files, Nix outputs, command arguments, or captured logs. It does not claim that Nix evaluation provisions deployed Samba passdb state.

### SMB endpoint and audit conformance

`tests/harness/verification-smb-operations.bats` evaluates the hidden share, ordinary-share tester denial, root ownership, link policy, capacity controls, and audit operation/prefix/sink configuration. Controlled audit fixtures preserve principal, client, share, operation, and run-scoped path fields. It proves intended configuration and parser behavior, while the live transaction and operator audit procedure prove deployed operation.

### Manual lifecycle and recovery procedures

`tests/specbase/manual-verification.md#verification-credential-lifecycle` provisions, rotates, and retires the Samba principal. It includes prerequisites, secret-safe invocation, active-session revocation, rollback, verification, and dated evidence.

`tests/specbase/manual-verification.md#live-verification-recovery` first blocks new tester sessions and terminates active ones, inventories direct-child run namespaces and audit records, accepts one strict run ID rather than a path, performs no-follow root-anchored removal or quarantine, verifies absence, and records the result. Manual evidence remains honest because exceptional operator actions cannot be safely automated before a narrow privileged role exists.

## Risks / Trade-offs

- **A hidden share is still addressable by name** -> Require authentication and tester-only authorization; do not rely on non-browseability.
- **Manual passdb handling is less reproducible** -> Specify a bounded lifecycle now, then replace materialization through a future Ops change when the pipeline and secret platform exist.
- **Tester credentials are compromised** -> Deny ordinary shares, limit writable capacity and paths, support session revocation/rotation, and audit mutations.
- **Shared credentials cannot enforce per-run secrecy** -> Claim cooperative collision isolation only; require a privileged broker before adding per-run principals.
- **Live evidence is mistaken for guest-share proof** -> Keep bindings separate and make deployed normal-share tests read-only.
- **Cleanup is interrupted by client or network loss** -> Preserve run identity in logs and provide session-safe exact operator recovery.
- **A future privileged probe pressures tester-admin into broad sudo** -> Require a separate proposal with a named operation and narrow authority before creating the role.

## Migration Plan

1. Land `establish-testing-operations` and `establish-test-quality`.
2. Add the locked tester Unix account, explicit tester denial on normal shares, authenticated Samba principal lifecycle, bounded root, hidden endpoint, and audit configuration.
3. Provision the initial passdb credential outside the repository and execute the lifecycle procedure once.
4. Add structural and operational conformance sources, including privilege, traversal, symlink, capacity, secret-leak, and ordinary-share negative controls.
5. Add the live transaction and separately exercise byte and inode exhaustion with strict client-side ceilings; induce controlled assertion and cleanup failures and confirm exact diagnostics and recovery.
6. Exercise deployed audit observation and residual-state recovery against the controlled run.
7. Update the Samba enforcement plan to keep guest writes in VMs and deployed normal-share probes non-mutating.
8. Validate all four governed pairs and rebase capability verification changes on the resulting boundaries.

Rollback blocks new tester sessions, terminates active sessions, records or removes residual namespaces, preserves audit evidence, disables the hidden endpoint, retires the passdb principal, and removes the Unix account. It preserves normal guest access and never grants tester authority over ordinary shares.
