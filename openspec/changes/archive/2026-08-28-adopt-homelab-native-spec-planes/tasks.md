## 1. Freeze and account for current truth

- [x] 1.1 Record baseline strict validation, coverage, orphan classes, discovered pair locators, requirement/scenario IDs, binding IDs, and evidence targets for the current 15 pairs.
- [x] 1.2 Review all 32 rows in `mapping.md` against the source pairs and confirm every keep, split, demote, and drop verdict with no unaccounted normative clause.
- [x] 1.3 Confirm the four dropped/demoted atoms—utility package presence, warning wording, Make target/help existence, and unspecified update cadence—have no surviving shared requirement or evidence target that would be lost accidentally.

## 2. Prepare the five-plane post-state off-tree

- [x] 2.1 Create a scratch post-state containing exactly the `service`, `estate`, `configuration`, `lifecycle`, and `governance` plane roots with the purposes, enforcement flavors, and lens assignments from `design.md`.
- [x] 2.2 Rebase the staged `behavior/nas-capabilities` pair to `service/nas-capabilities` without changing `service.nas-capabilities` or preserved pair-local IDs.
- [x] 2.3 Rebase the staged `architecture/nas-storage` pair to `estate/nas-storage` without changing `estate.nas-storage` or its pair-local IDs.
- [x] 2.4 Rebase the staged `ops/nas-realization` and `ops/nas-transitions` pairs to `configuration/nas-realization` and `lifecycle/nas-transitions` without changing their future IDs.
- [x] 2.5 Rebase all staged `agents/*` and `code-quality/enforcement-quality` pairs to their declared `governance/*` locators without changing future spec IDs.
- [x] 2.6 Verify the scratch tree contains every destination in `mapping.md`, every requirement has at least one scenario, every pair has `enforcement.yaml`, and no old-plane root or unknown locator remains.

## 3. Replace the plane model and generated instruments

- [x] 3.1 Replace `specbase/config.yaml`'s plane roster with the exact five-plane post-state and retain project context/rules that remain valid.
- [x] 3.2 Regenerate repo-specific Specbase skills and prompts from the resolved model so authoring guidance names the new roster and decision rules rather than frozen old-plane text.
- [x] 3.3 Update the review-panel lens configuration to scoped Service, Estate, Configuration, Lifecycle, and Governance lenses plus the cross-cutting Enforcement lens.
- [x] 3.4 Update test-tree routing so adds, modifications, renames, and deletions beneath `tests/**` select `governance.enforcement-quality` while preserving advisory/non-gating semantics.
- [x] 3.5 Update `tests/agents/specbase-instruments.sh` config, lens, validation, and test-quality-routing fixtures for the exact new roster, scopes, and policy locator; include missing/extra/scope-drift and rename/delete mutants.
- [x] 3.6 Execute the Specbase instrument checks through their native harness and record the resolved roster, lens set, routing observations, and results.

## 4. Migrate Service, Estate, Configuration, and Lifecycle evidence

- [x] 4.1 Run `tests/nas-vm.nix` and `tests/verify/nas-samba.bats` through their native VM/live harnesses; verify assertion-level observations still establish `samba-shares-exposed` and `guest-force-operator` and retain cleanup diagnostics.
- [x] 4.2 Replace or supplement the operator-access manual procedure with bounded SSH and `sudo -n` evidence when safe; otherwise add host, generation, time, freshness, limitations, and retained result metadata to the manual evidence.
- [x] 4.3 Implement the initial Estate review/reconciliation procedure for NAS file-sharing workload and pool ownership without claiming that evaluated options prove physical placement; record explicit limitations pending the typed registry.
- [x] 4.4 Strengthen `tests/specbase/current-bindings.sh` NAS configuration checks to evaluate selected pool import policy, stable host identity, forced-root-import setting, administrator account policy, and kernel/ZFS closure compatibility; remove source-text assertions when evaluated state is available.
- [x] 4.5 Execute the NAS Configuration checks through Nix evaluation/build and record expected values, observed values, lock revision, target system, and derivation result.
- [x] 4.6 Update the boot/deployment manual evidence format to record before/event/after state, host, active generation, pool state, elapsed time, freshness, and limitations.
- [x] 4.7 Execute `tests/harness/deployment-operations.bats` and `tests/verify/deployment.bats`; confirm controlled adapters cover orchestration semantics only and live observations cover point-in-time post-deploy health only.
- [x] 4.8 Perform or explicitly defer fenced boot and deployment runtime procedures; retain dated evidence or honest limitations without creating a hollow automated substitute.

## 5. Migrate Governance evidence

- [x] 5.1 Replace duplicate or text-only flake/pin bindings with evaluated output-shape, lock-resolution, stateVersion/pin consistency, and touched-host closure checks while retaining source-layout checks only where layout is the requirement.
- [x] 5.2 Execute the Nix repository checks through their native Nix/project harness and record the resolved attributes, lock revision, host closure results, and any source-layout diagnostics.
- [x] 5.3 Review `tests/harness/deployment-operations.bats` against `governance.deployment-control`; keep explicit plan/override/failure fixtures and remove any claim that fake adapters prove a physical deployment.
- [x] 5.4 Execute the deployment-control harness and record the resolved target/input observations and representative failure-mutant results.
- [x] 5.5 Add registry-level or equivalent conformance over every registered VM/test target for disposable subject and private-network boundaries; retain the existing NixOS VM isolation assertions as runtime evidence.
- [x] 5.6 Execute lint, routine test, KVM aggregate-selection, VM isolation, and live-verification runner sources through their native harnesses and record phase selection, exclusions, failure propagation, network state, and builder identity.
- [x] 5.7 Execute `tests/tooling/environment.bats` across supported systems and retain Governance review for catalogue role/scope/authority semantics.

## 6. Establish enforcement-quality governance

- [x] 6.1 Implement deterministic conformance for assertion scope, binding target resolution, evidence provenance/freshness/limitations, live mutation namespace, blast radius, and cleanup metadata without attempting to infer semantic adequacy mechanically.
- [x] 6.2 Add bad-binding/evidence fixtures that demonstrate rejection of helper-existence evidence, wrapper-only evidence, overbroad coverage, missing provenance, stale live evidence, and unsafe mutation metadata.
- [x] 6.3 For each reused evidence family materially changed by this migration, run one representative fault or mutation that proves the family fails for the intended reason and retains the distinguishing diagnostic.
- [x] 6.4 Update the Enforcement review lens to judge independent expectations, production-path fidelity, semantic coverage, environment limits, and maintenance value above deterministic gates.
- [x] 6.5 Run enforcement-quality conformance, mutation fixtures, and the review panel; record deterministic failures separately from review-strength findings.

## 7. Atomic cutover and cleanup

- [x] 7.1 Validate the complete scratch post-state with strict spec/change validation, coverage, orphan detection, unknown-root detection, and explicit pair discovery; require that every expected future locator is discovered, not merely parsable.
- [x] 7.2 Atomically replace the live roster, current spec tree, generated instruments, lens configuration, and test-quality routing with the validated post-state.
- [x] 7.3 Re-run `specbase status` and `specbase instructions` for this change under the new roster; confirm all staged delta pairs resolve at their future Service/Estate/Configuration/Lifecycle/Governance locators.
- [x] 7.4 Remove retired old-plane pair files and bindings only after confirming no surviving pair shares their targets; retain test sources still used by migrated bindings.
- [x] 7.5 Run project-native lint, routine tests, selected NixOS VM tests, safe live probes, strict Specbase validation, coverage, and orphan checks against the live post-state.
- [x] 7.6 Confirm no unknown roots, incomplete pairs, stale bindings, broken targets, unaccounted requirements, or unlensed review claims remain; record honest degraded states rather than adding hollow automation.
- [x] 7.7 Validate stack `homelab-native-governed-spec-planes-1e6a11e0` and confirm `introduce-typed-estate-registry` is the next unfinished member with the new roster available.
- [x] 7.8 Record rollback as a single revert of the atomic cutover and generated instruments; verify no running-host rollback is needed because runtime Nix configuration did not change.
