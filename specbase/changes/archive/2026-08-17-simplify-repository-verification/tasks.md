## 1. Preserve direct deployed behavior

- [x] 1.1 Reconcile the staged verification refactor so default `make verify` contains only the three deployment checks and three ordinary guest-share checks.
- [x] 1.2 Keep guest transactions collision-resistant, exactly scoped, interrupt-cleaned, non-recursive, and failing on cleanup residue.
- [x] 1.3 Run the six default live checks against the deployed NAS and confirm both ordinary shares list, write, read, delete, and unmount cleanly.

## 2. Retire the hidden verification subsystem

- [x] 2.1 Remove the verification module import, `tester` Unix identity, hidden Samba share, tmpfs, initializer, tester exclusions, and fixture audit configuration.
- [x] 2.2 Audit every current binding and repository reference before deleting fixture helpers, profiles, harnesses, ordinary-share tester inventory, and obsolete manual procedures.
- [x] 2.3 Activate the removal temporarily and confirm the tester account, hidden share, tmpfs mount, and fixture service are absent while default `make verify` still passes.
- [x] 2.4 Preserve rollback safety until the temporary activation passes, then document that obsolete external credential files may be deleted without reading, printing, or committing their contents.
- [x] 2.5 Retire the architecture, behavior, and ops requirements and bindings that govern only the removed subsystem; remove empty current pair directories after coherent promotion.

## 3. Add one optional Samba VM behavior scenario

- [x] 3.1 Implement `tests/nas-vm.nix` as one two-node private-network scenario using production Samba/service modules and temporary operator-owned backing paths.
- [x] 3.2 From the disposable client, enumerate `mediaBin` and `smolBoy`, mount each as a guest, complete one write/read/delete transaction on each, and unmount cleanly.
- [x] 3.3 Keep the scenario independent of physical ZFS paths, the physical NAS address, the physical LAN, production secrets, mDNS, and controlled broken variants.
- [x] 3.4 Link `nas-samba-vm` to the fixed aggregate VM derivation and execute it through the default NAS Linux/KVM store.
- [x] 3.5 Confirm the existing architecture testing-isolation source still proves disposable guests and private networking without adding duplicate isolation tests.

## 4. Separate fast, optional VM, and live operations

- [x] 4.1 Remove `vm` from the default non-live phase registry while preserving an explicit documented `make test-vm` target.
- [x] 4.2 Keep `make lint` static/evaluation-only, reduce `make test` to fast non-live checks, and keep `make verify` independently runnable and non-activating.
- [x] 4.3 Consolidate deployment, test, verify-runner, Make-surface, tooling, agent, and current-binding checks to representative high-leverage cases; remove variations that protect only spelling, fixture wording, or upstream tool behavior.
- [x] 4.4 Update `tests/harness/test-operation.bats` and `tests/harness/verify-runner.bats` to prove the final operation boundaries and failure propagation.
- [x] 4.5 Run `make lint`, `make test`, explicit `make test-vm`, and default `make verify` independently.

## 5. Simplify durable testing quality

- [x] 5.1 Replace the eleven-rule code-quality testing contract with the four retained behavior/invariant, exact-state, cleanup, and actionable-failure requirements.
- [x] 5.2 Update changed-tests routing and the code-quality/enforcement review residue without introducing automated tests solely to satisfy coverage.
- [x] 5.3 Run the changed-tests review and reject findings that demand test-only production machinery without a selected capability.

## 6. Validate, promote, and deliver

- [x] 6.1 Confirm `harden-nas-samba-enforcement`, `harden-nas-access-enforcement`, and `harden-nas-boot-enforcement` are superseded by this change and absent from the active change list.
- [x] 6.2 Run ShellCheck, strict change/current validation, merged coverage inspection, flake checks, diff checks, and the applicable review-panel lenses.
- [x] 6.3 Compare final test and production LOC with the recorded baseline and document removed machinery plus any intentionally retained meta-tests.
- [x] 6.4 Persist the simplified NAS generation only after temporary activation, default live verification, and rollback checks pass.
- [x] 6.5 Archive `simplify-repository-verification`, audit the staged index against unrelated worktree changes, commit only intended files, and push `main`.
