## Why

Repository verification has grown into a second production subsystem: a hidden authenticated SMB share, dedicated identity, credential lifecycle, bounded storage, auditing, and extensive tests of the test machinery. The operator instead wants a lean split between direct deployed behavior checks and an optional disposable VM integration test.

## What Changes

- Preserve the current default `make verify` contract: deployment reachability/system health plus guest-visible listing and bounded write/read/delete behavior on `mediaBin` and `smolBoy`.
- Add one optional two-node NixOS VM scenario that proves the same guest SMB behavior before deployment without joining the default `make test` gate.
- Keep `make lint`, a small deterministic `make test`, explicit `make test-vm`, and post-activation `make verify` as distinct operations.
- **BREAKING** Retire the test-only `tester` identity, hidden `homelab-verification$` share, credential files and rotation procedure, tmpfs, audit policy, fixture clients, live safety profiles, and their dedicated specifications.
- Remove or consolidate exhaustive negative fixtures and meta-tests that protect no plausible homelab regression; retain only high-leverage operation, failure-propagation, tooling, and isolation checks.
- Replace the eleven-rule testing-quality surface with a smaller durable rule: tests protect user-visible behavior or critical operational/structural invariants, and live mutation remains exactly scoped and cleanup-safe.
- Supersede `harden-nas-samba-enforcement`, `harden-nas-access-enforcement`, and `harden-nas-boot-enforcement`; only the lean optional Samba VM intent survives here.

## Planes

### Behavioral truth

- `behavior.storage.nas-samba`: preserve guest-visible enumeration and read/write behavior while adding optional VM evidence alongside the live probe (modified).
- `behavior.verification.smb-fixtures`: retire the test-only hidden endpoint as a behavioral capability (removed).

### Architectural truth

- `architecture.verification-identities`: retire the dedicated test principal, bounded fixture state, and mutation boundary (removed).
- `architecture.testing-isolation`: apply the existing private disposable VM boundary to the optional Samba client/server scenario (modified).

### Ops

- `ops.testing`: make the VM integration phase explicit and optional while preserving post-activation live verification (modified).
- `ops.verification.identity`: retire tester provisioning, external secret, and rotation machinery (removed).
- `ops.verification.smb-fixtures`: retire the hidden share, bounded state, auditing, and recovery procedure (removed).

### Code quality

- `code-quality.testing`: replace exhaustive test-of-test pressure with a lean behavior/invariant focus and bounded live cleanup expectations (modified).

## Enforcement intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| `samba-shares-exposed`, `guest-force-operator` | `test` | `tests/verify/nas-samba.bats` | The physical NAS advertises both ordinary shares and a guest completes an exactly scoped write/read/delete transaction on each. |
| `samba-shares-exposed`, `guest-force-operator` | `test` | `tests/nas-vm.nix` | A disposable client observes and uses production Samba behavior over a private VM network before deployment. |
| `test-stage`, `verify-stage`, optional VM operation | `test` | focused repository operation tests | Fast non-live checks, optional VM execution, and live verification remain distinct and failures propagate. |
| lean testing quality | `review` | `code-quality` lens | Changed tests protect plausible behavior or critical invariants without manufacturing test-only production machinery or exhaustive self-tests. |
| `test-subject-boundary`, `test-network-boundary` | `test` | `tests/nas-vm.nix` plus aggregate linkage | The optional VM remains disposable, private, included in the fixed aggregate, and unable to route to the physical LAN. |

Removed test-only verification truths intentionally receive no replacement binding.

## Impact

- Removes `hosts/nas/verification.nix` and its import, the deployed tester account/share/storage/audit configuration, local credential lifecycle documentation, and fixture helper/profile sources.
- Simplifies `Makefile`, flake runners/checks, repository harnesses, tooling checks, README guidance, current binding sources, and manual verification evidence.
- Adds or retains one optional `x86_64-linux` two-node Samba VM derivation runnable through `make test-vm` and the NAS KVM store.
- Leaves NAS access and boot behavior unchanged; no standalone access/boot hardening suite is introduced.
