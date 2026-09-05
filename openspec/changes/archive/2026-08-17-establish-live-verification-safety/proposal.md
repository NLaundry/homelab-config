## Why

Live verification should be attributable without granting tests operator authority over ordinary homelab data. Before capability checks begin mutating deployed services, the NAS needs a dedicated testing principal, a confined fixture boundary, and an auditable recovery path.

## What Changes

- Add an authenticated `tester` role distinct from human operators and future deployment identities.
- Explicitly deny the tester access to ordinary SMB shares while preserving their existing guest semantics.
- Add a non-browseable SMB verification endpoint backed only by bounded, dedicated mutable state.
- Require every repository-driven verification mutation to use an identifiable collision-resistant run namespace.
- Provision the tester as a non-login, non-sudo Unix account and an operator-managed Samba principal whose credential stays outside Git, generated Nix outputs, process arguments, and test logs.
- Add operator procedures for principal provisioning/retirement, credential rotation, audit observation, and exact cleanup of residual test-owned state.
- Defer `tester-admin` until a concrete privileged verification operation earns a narrowly constrained role; deployment remains a separate future identity.

## Planes

### Behavioral truth

- `behavior.verification.smb-fixtures`: authenticated verification-client access, disposable SMB transactions, denial without tester credentials, and operator-visible attribution (new).

### Architectural truth

- `architecture.verification-identities`: separation of testing, operator, and deployment authority plus confinement and capacity boundaries for live mutation (new).

### Ops

- `ops.verification.identity`: selected Unix/Samba principals, credential materialization, and principal/credential lifecycle for the tester role (new).
- `ops.verification.smb-fixtures`: selected hidden share, ordinary-share denial, bounded backing state, audit configuration, and residual-state recovery procedure (new).

## Spec pairs

- `behavior.verification.smb-fixtures` -> paired live Bats access/transaction source plus manual audit observation.
- `architecture.verification-identities` -> paired structural conformance source over identity privileges, endpoint roots, run naming, and capacity boundaries.
- `ops.verification.identity` -> paired Nix/account conformance source plus manual Samba-principal and credential lifecycle procedure.
- `ops.verification.smb-fixtures` -> paired endpoint/audit conformance source plus manual residual-state recovery procedure.

## Enforcement intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| authenticated fixture access and transaction | `test` | `tests/verify/smb-fixtures.bats` | The testing principal authenticates, clients without its current credential fail, and the tester creates, reads, and removes its run-scoped fixture. |
| operator-visible mutation attribution | `manual` | `tests/specbase/manual-verification.md#live-verification-audit` | An operator queries deployed audit output by run identity and observes principal, operation, and path. |
| identity, mutation, and namespace boundaries | `static-analysis` | `tests/harness/verification-identity-boundary.bats` | Evaluated identities, privilege sets, endpoint roots, and controlled paths preserve separation and confinement. |
| runtime capacity boundary | `test` | `tests/verify/profiles/smb-fixture-capacity.bats` | The deployed verification endpoint rejects byte and inode allocation at its finite limit while an ordinary share remains independently listable. |
| selected Unix account and secret handling | `test` | `tests/harness/verification-identity-operations.bats` | Nix evaluation and controlled fixtures establish the non-login account and reject secret-bearing outputs. |
| Samba-principal and credential lifecycle | `manual` | `tests/specbase/manual-verification.md#verification-credential-lifecycle` | An operator provisions, rotates, revokes active sessions, verifies, and retires the principal without exposing its credential. |
| hidden endpoint and audit realization | `test` | `tests/harness/verification-smb-operations.bats` | Evaluated Samba/storage settings and controlled fixtures establish authorization, ordinary-share denial, bounded state, and audit configuration. |
| residual-state recovery | `manual` | `tests/specbase/manual-verification.md#live-verification-recovery` | An operator revokes active sessions and removes one exact run namespace without granting standing test administration. |

## Impact

- Adds a NAS testing Unix account, Samba principal, hidden SMB verification share, explicit tester denial on normal shares, bounded storage ownership, passdb lifecycle, and audit settings.
- Adds a live Bats transaction and structural/operational conformance sources.
- Depends on `establish-testing-operations` and `establish-test-quality`.
- Requires the Samba enforcement plan to keep guest-write proof in disposable VMs and make deployed normal-share checks non-mutating.
- Does not add `tester-admin`, deployment automation, a general secrets platform, or tester access to ordinary share contents.
