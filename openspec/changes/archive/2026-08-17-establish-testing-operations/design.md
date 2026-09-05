## Context

The repository currently exposes `make check` as a flake evaluation and `make test` as `nixos-rebuild test` against the physical NAS. The root `Makefile` is already the operator entry point for repository lifecycle work, but the permanent deployment pair currently owns that shared interface. Adding testing there would either mix concerns or repeat the same Makefile contract in another focused pair.

The operator workstation is macOS/aarch64. NixOS VM tests for the x86_64 NAS therefore need a remote Linux store with virtualization support. The physical NAS already performs remote Linux builds, loads `kvm-intel`, and trusts the operator for Nix operations, so it is the least-infrastructure initial execution host. A dedicated testing/CI host is intentionally deferred. The prerequisite `establish-reproducible-repository-tooling` change supplies the shared operator tool set, development shell, and Nix-packaged Bats command.

The permanent Ops truth should place the common command interface at the root and leave operation meanings with focused pairs. The separation between disposable test subjects, their compute provider, and the physical LAN is enduring architecture rather than runner configuration, so it receives its own architecture pair. Test-writing qualities and the checks that prove individual NAS behaviors belong to later changes.

## Goals / Non-Goals

**Goals:**

- Establish the root `Makefile` once as the repository-wide Ops command surface.
- Let focused Ops pairs define named operations and semantics without repeating Makefile ownership.
- Give fast `lint`, complete non-live `test`, and deployed `verify` unambiguous meanings.
- Adopt the NixOS test driver for ephemeral VM tests and Bats for live checks.
- Make test execution reproducible through Nix while keeping test logic in the runner best suited to each environment.
- Use the physical NAS store as the initial Linux/KVM execution destination without making the operation contract depend permanently on that host.
- Preserve temporary physical activation under the clearer `try` name.
- Provide one explicit non-live phase registry so every automated source has a discoverable default gate that later enforcement changes can extend one spec pair at a time.
- Run deployed verification automatically after successful immediate activation while preserving standalone health checks and explicit no-rollback failure semantics.
- Preserve a structural boundary in which the execution host supplies compute only and test guests cannot join the physical homelab LAN.

**Non-Goals:**

- Add the substantive Samba, user-access, ZFS, or deployment-verification tests in this change.
- Define what makes an individual test good; that belongs to a later `code-quality/testing` pair.
- Add continuous monitoring, observability export, or a dedicated CI host.
- Run test VMs on the physical LAN or activate candidate configuration on the execution host.
- Refactor production NAS modules unless a later concrete test shows that a new stable boundary is required.

## Decisions

### Treat current Specbase artifact instructions as authoritative

The repository's generated workflow-skill prose still contains legacy `enforcement.md` and planned/active guidance. This change follows `specbase instructions enforcement --change establish-testing-operations --json`: sibling compact `enforcement.yaml` maps, requirement-level coverage, and exactly `type`, `covers`, and `source`. Refreshing the generated skills is agents-plane work and remains separate from this testing-operations change.

### Make the root Makefile the common Ops interface

The new `ops.repository-operations` pair owns one universal rule: the root `Makefile` declares an operation registry and every registered name resolves to a documented, same-named phony target. Focused pairs own required membership and operation meanings. `ops.deployment` requires `deploy`, `boot`, `try`, `dry`, and `build`; `ops.testing` requires `lint`, `test`, and `verify`.

A generic Bats conformance test inspects Make's declared registry and database rather than parsing Markdown or grepping command text. Focused-pair sources verify that their required names are registered and exercise each operation's own mapping. Adding another Ops capability therefore changes its focused requirement/source and the implementation registry, not the root spec.

### Use three testing stages

The `lint` operation runs strict validation of current governed specs (`specbase validate --specs --strict`) followed by evaluation of every supported-system flake check with `nix flake check --all-systems --no-build`. The no-build mode is part of the stage boundary: it prevents a Linux operator from executing the VM check during lint. Lint does not validate every unfinished change; under compact enforcement, active proposals may legitimately reference sources that land during their own implementation. Each change remains responsible for `specbase validate <change> --type change --strict` before archive. `lint` does not start VMs or address live homelab services.

The `test` operation is the complete non-live gate. It runs `lint` first, then dispatches every phase in an explicit registry covering the repository harness, tooling environment, agent instruments, current governed bindings, and the aggregate x86_64-linux NixOS VM derivation. Each phase remains directly runnable for diagnosis, but adding a new non-live family must also register its default phase so automation does not depend on change-specific knowledge. Any phase failure stops the gate.

The VM phase builds the fixed aggregate derivation in the selected remote Linux/KVM store. The `architecture.testing-isolation` pair, rather than the Ops pair, owns the durable rule that test subjects are disposable guests, the execution host remains compute-only, and guest networks do not reach the physical LAN.

The `verify` operation invokes the repository's Bats live-verification suite from the operator side. It may inspect hosts over SSH and exercise client protocols against deployed endpoints. A failing Bats test must make the operation fail, and standalone `verify` never activates a system.

The current temporary activation operation moves from `test` to `try`; the underlying `nixos-rebuild test` action does not change. After successful `try` or `deploy` activation, the same default `verify` suite runs as a postcondition. Activation failure prevents verification. Verification failure makes the operation fail but performs no automatic rollback, so diagnostics state that activation succeeded and the new temporary or persistent generation remains active. `boot`, `dry`, and `build` do not verify because they do not activate immediately.

The current `check` name is replaced by `lint` so the operator vocabulary reflects intent rather than an overloaded generic check.

### Package both runners through the flake

The flake exposes an x86_64-linux check derivation for the VM harness plus separate system-appropriate Bats entry points for harness conformance and deployed verification. The Make-owned non-live phase registry composes those packaged entry points with the source-native tooling, agent, and current-binding modes through the shared development environment. These entry points consume the shared Bats/tool definitions from `ops.tooling`; the live runner carries both Bats and the selected SSH transport, while the harness adds only its task-specific command dependencies. Shell-level conformance is written as `.bats` tests; `.sh` files are reserved for actual wrappers or shared helpers, and live checks remain in a separate verification suite.

Small Bats fixtures prove operation routing and pass/fail propagation, while the NixOS test-driver fixture proves disposable networked guests can run. These are evidence for testing machinery and boundaries only and must not be presented as coverage of NAS behavior.

### Run VM tests in a replaceable remote Linux/KVM store

The initial `test` implementation targets the physical NAS through one documented, overridable store URI that provides `x86_64-linux`, `kvm`, and `nixos-test`. The Make target always selects the same flake check attribute; overriding the store changes execution placement, not derivation identity. An actual run proves the default NAS can execute the fixture, while a controlled command-level fixture proves an alternate compatible URI is forwarded honestly without claiming that a second execution host already exists.

A standard multi-user `--builders` declaration was tested first. On the Darwin operator, that mode delegates SSH establishment to `nix-daemon`; macOS Local Network Privacy denies the daemon-owned SSH process even though the selected `/usr/bin/ssh` transport works from the foreground operator process. Targeting the SSH store directly keeps the foreground transport and is therefore the bounded Darwin-compatible choice. `--eval-store auto` preserves local evaluation while the remote store coordinates Linux builds and retains their outputs.

The physical NAS is compute infrastructure for the test derivation, not the test subject: candidate test nodes run under QEMU/KVM, communicate only on test-driver virtual networks, and do not activate a generation on the execution host.

### Keep one small central test tree

The initial layout is a central `tests/` directory because infrastructure scenarios exercise composed capabilities rather than one source file. The change adds only the files needed for operation and runner conformance. Later changes may add capability-named VM and Bats files without establishing a deeper hierarchy in advance.

Reusable protocol probes are extracted only after both VM and live suites need the same transaction. The change does not create a speculative helper framework.

### Bind each governed pair at its own boundary

The `ops.repository-operations` enforcement checks the generic Make registry/surface. Deployment enforcement checks deployment action expansion and input overrides. Testing enforcement checks validation scope, runner selection, remote-store forwarding, and live-runner failure propagation. Architecture enforcement checks the compute-provider and network boundaries through the operation wrapper and VM fixture.

Compact indexes contain only `type`, requirement-level `covers`, and `source`. Execution details and limitations live here, in tasks, and in the sources:

| Source | What it proves | Explicit limit |
|---|---|---|
| `tests/harness/make-operation-surface.bats` | Registered operations are documented same-named phony targets | Does not assign leaf semantics |
| `tests/harness/deployment-operations.bats` | Deployment actions and overrides expand correctly; immediate activation sequences verification and propagates its failure without rollback claims | Does not perform a live deployment |
| `tests/harness/lint-operation.bats` | Current-spec and flake failures propagate independently, and the packaged CLI accepts valid compact enforcement while rejecting a broken source | Does not judge whether every claim is substantively correct |
| `tests/harness/test-operation.bats` | Complete non-live phase dispatch, fixed VM check selection, remote-store forwarding, failure propagation, and no deployment activation | A second physical execution host is not required for the override fixture |
| `tests/harness/nixos-vm.nix` | Disposable guests boot and communicate only on the private test topology | Does not prove NAS product behavior |
| `tests/harness/verify-runner.bats` | The live runner carries the selected SSH transport and propagates Bats pass/fail status | Does not prove deployed behavior until substantive checks exist |

These sources prove operational machinery and architecture boundaries, not product coverage. Later changes bind substantive VM and Bats checks directly to the existing pairs whose claims they exercise.

### Stop evidence recursion at explicit trust anchors

An enforcement binding is an index from a normative requirement to evidence; it does not create another normative requirement merely because the evidence is executable. This change governs the testing operations because their stage behavior and isolation boundaries are durable repository capabilities, then stops at three trust anchors: deterministic Specbase validation, executable source-native checks with controlled fixtures, and named review/manual procedures where automation would overclaim.

A conformance fixture does not receive another spec and test solely because it is evidence. It earns a governed pair only if the fixture or runner later becomes a separately consumed durable capability. The cross-cutting `enforcement` review lens judges whether a changed binding's source genuinely exercises its requirement; that judgment is a terminal review activity, not a request for an infinite chain of meta-tests.

## Risks / Trade-offs

- **The NAS spends resources running test VMs** -> Keep the initial harness small, constrain VM memory, and avoid parallel VM jobs by default.
- **The NAS is unavailable, so isolated tests cannot run** -> Surface remote-store unavailability as an execution prerequisite; move to the separately captured dedicated-CI-host idea later.
- **Remote KVM is misconfigured** -> Add an execution-store preflight/conformance check and document the required advertised `kvm` system feature.
- **The common Make surface drifts from focused operation specs** -> Use one generic root conformance check plus focused checks that exercise every operation each leaf defines.
- **A non-live evidence family exists but the default test gate omits it** -> Keep an explicit phase registry and test it against an independent expected inventory.
- **Activation succeeds but post-activation verification fails** -> Return failure, preserve the activated generation, and state clearly that no rollback was attempted.
- **A working harness may be mistaken for meaningful NAS coverage** -> Label harness fixtures as conformance-only and leave NAS enforcement states unchanged until dedicated follow-on changes bind real tests.
- **Renaming operations disrupts operator muscle memory** -> Update README examples and Make help atomically; fail clearly for obsolete names rather than silently preserving ambiguous semantics.
- **`lint` could be blocked by unfinished proposals with not-yet-created compact sources** -> Validate current governed specs in `lint`; validate each active change explicitly at the end of its own implementation.
- **Live Bats checks can mutate production state** -> This foundation adds no substantive live transactions; the later test-quality pair will govern repeatability and cleanup before such tests are added.

## Migration Plan

1. Confirm the archived Specbase drift repair and `establish-reproducible-repository-tooling` leave current validation, coverage, and the shared operator tool environment green.
2. Add task-specific Bats entry points and the x86_64-linux NixOS VM harness-conformance derivation using the shared tool definitions.
3. Configure the physical NAS as the default overridable remote Linux/KVM test store and verify remote KVM execution.
4. Refactor the root Makefile around an explicit operation registry, rename `check` to `lint`, rename temporary activation `test` to `try`, add complete non-live `test` plus standalone live `verify`, and chain verification after successful immediate activation.
5. Add generic root-surface, focused testing/deployment, phase-inventory, sequencing, and architecture-boundary conformance sources.
6. Remove superseded deployment selectors from the transitional compact-migration source.
7. Update README command documentation and clearly distinguish remote-store execution from testing the deployed NAS.
8. Run source-native checks and validate all four governed pairs.
9. Follow with separate changes for `code-quality/testing` and per-capability enforcement, beginning with Samba.

Rollback restores the former Make target names and removes the harness outputs; it does not require changing the physical NAS generation because VM tests never activate on the execution host.
