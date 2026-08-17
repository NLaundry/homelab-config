## 1. Prerequisites and identity realization

- [x] 1.1 Land `establish-testing-operations` and `establish-test-quality`, then confirm live verification failures remain non-zero and advisory quality review is available for new tests.
- [x] 1.2 Add a locked `tester` Unix account with a stable identity and no interactive shell, SSH keys, sudo membership, deployment membership, or access to ordinary NAS data.
- [x] 1.3 Add explicit tester denial to every ordinary Samba share while preserving existing guest access, and confirm the verification share never forces operations to `operator`.
- [x] 1.4 Write the Samba-principal lifecycle runbook with prerequisites, passdb persistence, stdin-only provisioning, active-session revocation, rotation, retirement, rollback, verification, and dated evidence.
- [x] 1.5 Provision and rotate the initial tester credential; store the client authentication file as an operator-owned mode-`0600` regular non-symlink outside the repository and verify no secret appears in arguments or output.

## 2. Verification storage and SMB endpoint

- [x] 2.1 Create a dedicated verification state boundary with an operator-owned root, fixed run-child layout, tester-minimal permissions, and no ordinary data.
- [x] 2.2 Enforce finite byte and inode capacity independently of ordinary storage, then prove exhaustion fails without consuming ordinary-data capacity.
- [x] 2.3 Add a non-browseable Samba verification share that requires the tester credential, disables wide-link traversal, and rejects guest, retired-credential, and ordinary-share tester access.
- [x] 2.4 Configure Samba auditing for namespace creation, file creation/write, rename, unlink, and directory removal with tester-nonwritable output containing principal, client, share, operation, and path.
- [x] 2.5 Add run-ID and path-containment helpers that exclusively create strict collision-resistant direct-child namespaces, accept run IDs rather than arbitrary paths, reject traversal/symlinks/duplicates, and remove exact targets without prefix globs.

## 3. Structural and operational evidence

- [x] 3.1 Implement `tests/harness/verification-identity-boundary.bats` with evaluated identity/privilege/path/capacity assertions and controlled traversal, symlink, collision, cross-run-helper, broad-deletion, and ordinary-state failures.
- [x] 3.2 Link and execute the `verification-identity-boundary` static-analysis binding through the packaged harness, recording its native command and result.
- [x] 3.3 Implement `tests/harness/verification-identity-operations.bats` with Unix-account evaluation and controlled secret-leak fixtures for files, derivations, arguments, and captured output.
- [x] 3.4 Link and execute `verification-identity-operations`, then execute `tests/specbase/manual-verification.md#verification-credential-lifecycle` and record both results.
- [x] 3.5 Implement `tests/harness/verification-smb-operations.bats` with evaluated share/root/ordinary-denial/link/capacity/audit assertions and controlled attribution fixtures.
- [x] 3.6 Link and execute `verification-smb-operations` through the packaged harness, recording its native command and result.

## 4. Live behavioral evidence, audit, and recovery

- [x] 4.1 Implement `tests/verify/smb-fixtures.bats` to read the protected authentication file, reject guest and retired credentials, perform an exclusive create/read/remove round trip, and confirm absence.
- [x] 4.2 Implement the separately selected `tests/verify/profiles/smb-fixture-capacity.bats` with strict client-side byte, file-count, and time ceilings; prove both byte and inode exhaustion fail while an ordinary share remains independently listable, then clean the exact run namespace.
- [x] 4.3 Exercise a controlled assertion failure after fixture creation and confirm registered cleanup preserves the original failure while removing the exact run namespace.
- [x] 4.4 Exercise a controlled cleanup failure and confirm non-zero status plus the exact residual run identity before invoking recovery.
- [x] 4.5 Execute the live transaction and capacity profile from the home deployment environment, then complete `tests/specbase/manual-verification.md#live-verification-audit` with prerequisites, bounded time/run query, expected records, limitations, and dated evidence.
- [x] 4.6 Complete `tests/specbase/manual-verification.md#live-verification-recovery` with prerequisites, connection blocking, active-session termination, audit/direct-child inventory, strict run-ID validation, no-follow exact cleanup or quarantine, rollback, verification, and dated evidence.
- [x] 4.7 Exercise recovery against the controlled residue, confirm a target outside the root is rejected, link both manual bindings, and record outcomes.

## 5. Validation and downstream boundaries

- [x] 5.1 Run every source in its native harness, strict change validation, current-spec validation, coverage, and the advisory review panel over all changed tests and helpers.
- [x] 5.2 Confirm no `tester-admin`, unrestricted sudo, deployment authority, ordinary-data access, per-run authorization claim, or general secret platform entered the implementation.
- [x] 5.3 Update `harden-nas-samba-enforcement` so VM evidence owns guest-write semantics, deployed normal-share checks remain non-mutating, and no restricted fixture transaction is bound to `guest-force-operator`.
- [x] 5.4 Exercise rollback in a controlled sequence: block new tester sessions, terminate active sessions, record or recover residue, preserve audit evidence, disable the endpoint, retire the passdb principal, and remove the Unix account without changing normal guest behavior.
