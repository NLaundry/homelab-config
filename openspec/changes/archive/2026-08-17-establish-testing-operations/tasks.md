## 1. Prerequisites and runner packaging

- [x] 1.1 Confirm the archived `repair-specbase-agent-drift` and `establish-reproducible-repository-tooling` changes leave strict current-spec validation, strict coverage, and the shared operator tool environment green; capture current compact-enforcement instructions before implementation.
- [x] 1.2 Verify the physical NAS exposes `/dev/kvm` and accepts remote Nix builds, then define one documented overridable remote-store URI that provides `x86_64-linux`, `kvm`, and `nixos-test`.
- [x] 1.3 Extend `flake.nix` without an additional flake utility dependency to expose task-specific harness and deployed-verification Bats entry points from the shared tooling definitions, plus a stable aggregate `checks.x86_64-linux` VM-test derivation.
- [x] 1.4 Add `tests/harness/nixos-vm.nix` as a resource-bounded NixOS test-driver fixture whose disposable guests boot, communicate on an explicit private test network, and have no physical-LAN address or route.
- [x] 1.5 Add minimal pass/fail fixtures and `tests/harness/verify-runner.bats` to prove Bats runner invocation and non-zero failure propagation without claiming deployed NAS coverage.
- [x] 1.6 Add `tests/harness/lint-operation.bats` with controlled command fixtures that independently prove current-spec and flake-check failures propagate without mutating governed specs or the real flake.
- [x] 1.7 Add `tests/harness/test-operation.bats` to prove fixed aggregate-check selection, default and overridden remote-store forwarding, and absence of any deployment activation command.

## 2. Operational command and documentation surface

- [x] 2.1 Refactor the root `Makefile` around an explicit operation registry, with documented same-named phony targets for the deployment and testing operations.
- [x] 2.2 Replace `check` with `lint`, running `specbase validate --specs --strict` before evaluation-only `nix flake check --all-systems --no-build` and propagating either failure.
- [x] 2.3 Rename temporary physical activation from `test` to `try` while preserving its underlying `nixos-rebuild test` action.
- [x] 2.4 Add `test` for the fixed aggregate x86_64-linux VM derivation, default it to the NAS Linux/KVM store, and make only execution placement overridable.
- [x] 2.5 Add `verify` for the Nix-packaged Bats live suite and propagate selected Bats failures through Make.
- [x] 2.6 Add `tests/harness/make-operation-surface.bats` to inspect the Make registry/database and reject missing, undocumented, differently named, or non-phony registered targets without parsing Specbase Markdown.
- [x] 2.7 Add `tests/harness/deployment-operations.bats` to assert every deployment action plus `HOST`, `TARGET`, and `FLAKE` overrides through dry command expansion.
- [x] 2.8 Remove the superseded deployment-operation functions/selectors from `tests/specbase/current-bindings.sh` after the new deployment source passes.
- [x] 2.9 Update Make help and `README.md` for `lint`, isolated `test`, temporary `try`, `deploy`, and live `verify`, including the compute-provider and physical-LAN isolation boundaries.
- [x] 2.10 Add an explicit non-live phase registry and make `test` run lint plus every registered harness, tooling, agent-instrument, current-binding, and VM phase with failure propagation.
- [x] 2.11 Make successful `try` and `deploy` activations run the default `verify` suite afterwards; prevent verification after activation failure and report verification failure without claiming rollback.
- [x] 2.12 Update Make help and `README.md` for the complete non-live gate, standalone verification, automatic post-activation verification, and no-rollback semantics.

## 3. Source-native evidence

- [x] 3.1 Run `tests/harness/make-operation-surface.bats` against controlled Make fixtures and confirm it rejects a missing, undocumented, differently named, and non-phony registered target.
- [x] 3.2 Run `tests/harness/deployment-operations.bats` and confirm it detects an incorrect deployment action and an ignored override without executing a deployment.
- [x] 3.3 Run `tests/harness/lint-operation.bats`, then run `make lint`; confirm controlled Specbase and flake failures propagate independently while the restored repository passes.
- [x] 3.4 Run the complete `make test` gate against the default NAS store and confirm every registered phase passes and the VM fixture executes with KVM; use the operation fixture to confirm an alternate compatible store URI is forwarded without changing the selected derivation.
- [x] 3.5 Confirm the VM fixture uses only its declared private topology and the operation source contains no candidate activation path on the execution host.
- [x] 3.6 Run `tests/harness/verify-runner.bats` and confirm its controlled failing fixture makes the wrapped Bats runner fail while the conformance suite itself reports success.
- [x] 3.7 Confirm every compact binding source and selector exists and passes its native mode; there is no planned/active status transition in compact enforcement.
- [x] 3.8 Extend the test-operation source with an independent phase inventory plus controlled local-phase and VM-phase failures, and confirm each failure makes `test` fail before success is reported.
- [x] 3.9 Extend the deployment source to prove `try` and `deploy` verify only after successful activation, propagate verification failure with a no-rollback diagnostic, and leave `boot`, `dry`, and `build` unverified.

## 4. Validation and handoff

- [x] 4.1 Run every source-native check, `specbase validate establish-testing-operations --type change --strict`, `specbase validate --specs --strict`, and `specbase coverage --strict`.
- [x] 4.2 Confirm `ops.repository-operations` owns only the generic Make registry, `ops.testing` and `ops.deployment` own operation selection/semantics, and `architecture.testing-isolation` owns compute-provider and network boundaries.
- [x] 4.3 Confirm harness fixtures are described only as runner/boundary evidence and are not bound to Samba, ZFS, user-access, or deployment-success behavior.
- [x] 4.4 Confirm `lint` remains green in the presence of unfinished proposals while this change's own strict validation catches unresolved compact sources before archive.
- [x] 4.5 Record follow-on boundaries for `code-quality/testing`, Samba VM/live enforcement, NAS user access, ZFS runtime verification, and deployed-generation verification without implementing them here.
- [x] 4.6 Run the architecture, Ops, enforcement, and completeness review panel over the revised command contract and fix every verified finding before archive.
