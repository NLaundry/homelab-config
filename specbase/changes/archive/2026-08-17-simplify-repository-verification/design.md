## Context

The repository currently has about 2,964 lines of test code versus about 785 lines of host, Nix, flake, and Make configuration. Roughly 1,189 lines belong to a test-only SMB subsystem that introduced a deployed identity, secret lifecycle, hidden share, bounded storage, auditing, recovery, and tests of those mechanisms. Current live verification has since converged on six direct operator/user outcomes, making the hidden subsystem unnecessary.

Three pending hardening changes were drafted when behavioral enforcement was largely configuration serialization. Direct live Samba behavior now exists, access is already exercised by deployment, and boot persistence remains honestly manual. Their broad VM and negative-fixture matrices would continue the same verification recursion.

## Goals / Non-Goals

**Goals:**

- Keep default live verification understandable as deployed user/operator behavior.
- Keep one optional pre-deployment NixOS VM test for realistic Samba behavior.
- Make fast static checks, small deterministic tests, optional VM integration, and live verification distinct operations.
- Remove the hidden SMB fixture subsystem and the specifications that exist solely to govern it.
- Reduce repository tests to high-leverage checks for plausible regressions.

**Non-Goals:**

- Add ZFS, access, monitoring, or reboot automation.
- Simulate physical ZFS pools in VMs.
- Make the VM test part of the default `make test` gate.
- Preserve complete automated coverage as a goal in itself.
- Test Nix, Bats, Specbase, or the NixOS test framework beyond one repository integration boundary.

## Decisions

### Default verification remains user-facing

The default runner selects only top-level live Bats files. Deployment checks establish SSH reachability, systemd health, and a valid active generation. Samba checks establish guest enumeration and one exactly scoped write/read/delete transaction on each ordinary share. Test diagnostics, controlled failures, credential rotation, and capacity exhaustion do not join the default suite.

### Ordinary shares are the live Samba subject

The deployed contract is guest access to `mediaBin` and `smolBoy`, so live verification uses those shares directly. Each transaction creates one collision-resistant verifier-prefixed directory, touches only one file beneath it, and removes that exact directory before unmount. Interrupt cleanup is registered after resource acquisition. No recursive or broad deletion is permitted.

### The hidden verification subsystem is retired rather than relocated

Moving hidden-share tests to profiles retains all production and maintenance complexity without proving additional user behavior. The tester account, Samba principal, secret files, hidden share, tmpfs, audit policy, fixture helpers, profiles, and recovery procedures are removed together. Archived changes retain historical rationale; current empty governed pairs are removed after their requirements and bindings are retired.

### One optional two-node VM provides pre-deployment confidence

A single `x86_64-linux` NixOS test uses a disposable Samba server and client on the existing private test network. The server imports the production service modules but substitutes temporary operator-owned paths for physical storage. The client enumerates both shares and completes a guest mount/write/read/delete/unmount round trip. The scenario has no controlled broken variant, physical LAN access, real NAS address, or fake ZFS claim.

The existing fixed aggregate remains the derivation identity, while `make test-vm` selects it through the overridable Linux/KVM test store. A compact derivation-graph assertion keeps both the isolation harness and Samba scenario connected to that aggregate. `make test` does not select it automatically.

### Repository meta-tests are capped by plausible regression value

Keep representative checks for deployment ordering and failure propagation, runner selection, essential tooling reproducibility, current Specbase validity, and VM aggregate linkage. Consolidate or remove matrices that vary only target spelling, fixture failure wording, registry shrinkage, or behavior owned by an upstream tool. A test-of-test is retained only when a small repository helper contains meaningful branching whose failure could falsely report deployment success.

### Existing hardening proposals are superseded

`harden-nas-samba-enforcement` is replaced by the optional VM scope in this change. `harden-nas-access-enforcement` and `harden-nas-boot-enforcement` add no selected behavior and are rejected rather than implemented. Their directories are removed once this proposal is apply-ready; this proposal records the decision in durable archive history.

## Enforcement design

### Live Samba behavior

- **Observations:** guest enumeration contains `mediaBin` and `smolBoy`; each share mounts without credentials; an exactly scoped file round trip succeeds; cleanup and unmount succeed.
- **Harness:** packaged Darwin live Bats runner against the inventory NAS endpoint.
- **Failure signal:** non-zero Bats result naming the share and unestablished operation; cleanup residue remains a failure.
- **Boundary:** proves current guest behavior on the physical NAS, not mDNS discovery, ZFS health, or future reboot persistence.

### Optional Samba VM behavior

- **Observations:** a separate disposable client enumerates and mounts both production-configured shares, completes one guest round trip on each, and both guests expose only the declared private interface with no default or physical-LAN route.
- **Harness:** NixOS test driver on the selected `x86_64-linux` Linux/KVM store using only private virtual networking and temporary backing paths.
- **Failure signal:** the Nix derivation fails with the client command and node context.
- **Boundary:** proves module composition before deployment, not physical storage, router policy, mDNS on the physical LAN, or the deployed generation.

### Operation separation

- **Assertions:** `make test` runs the declared fast non-live phases without VM or live access; `make test-vm` selects the fixed aggregate and forwards only the execution store; `make verify` remains independently runnable and non-activating; activation operations verify afterward.
- **Harness:** a consolidated Bats operation suite with controlled command shims.
- **Failure signal:** non-zero result with the operation boundary that was violated.
- **Boundary:** proves repository orchestration, not the external tools' internal behavior.

### Lean testing quality

- **Observations:** changed tests protect a user-visible outcome or a critical structural/operational invariant; live mutation is exactly scoped and cleanup-safe; failures identify the missing outcome.
- **Harness:** changed-tests routing to the existing code-quality and enforcement review lenses after deterministic gates.
- **Failure signal:** advisory findings identify unnecessary test-only machinery, copied or hollow evidence, or unsafe mutation.
- **Boundary:** judgment remains review evidence; no synthetic test is added merely to automate the review rule.

## Risks / Trade-offs

- **A removed fixture identity previously provided credential-rotation evidence** -> Accept removal because the identity is not a selected capability; ordinary guest behavior is the product contract.
- **The optional VM is not run for every change** -> Keep it one explicit command and document it for Samba/service changes; post-activation verification remains automatic.
- **Ordinary-share verification mutates real storage** -> Use one unique namespace, exact non-recursive cleanup, interrupt traps, and loud residue reporting.
- **Fewer negative fixtures may miss a harness regression** -> Retain only branches capable of creating a false deployment-success result; rely on straightforward shell, review, and direct behavior otherwise.
- **Coverage becomes degraded or pair counts shrink** -> Treat that as an honest mirror; remove obsolete truths rather than replacing them with hollow evidence.

## Migration Plan

1. Preserve the staged direct deployment and ordinary-share live checks, but remove hidden-profile relocation and diagnostic fixtures that the lean design does not retain.
2. Implement and run the one two-node Samba VM scenario through `make test-vm` on the NAS KVM store.
3. Remove the verification module from the NAS configuration, activate temporarily, and confirm the tester account, hidden share, tmpfs, and related audit policy are absent while ordinary shares pass live verification.
4. Remove local tracked references and document that obsolete operator-owned credential files may be deleted after rollback confidence is established; never print or commit their contents.
5. Consolidate Make phases, harnesses, tooling checks, current bindings, and testing-quality rules.
6. Retire the test-only governed pairs and archive this change after strict current validation, honest coverage inspection, optional VM success, live verification, and review.
7. If rollback is required before archival, restore the verification module and prior current pairs from version control; credential material remains external and is not reconstructed by the repository.
