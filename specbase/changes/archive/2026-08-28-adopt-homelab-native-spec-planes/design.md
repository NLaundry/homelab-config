## Context

The repository has 15 governed pairs and 32 requirements across Behavior, Architecture, Ops, Code-quality, and Agents. Coverage is structurally healthy—no hanging, stale, broken, or orphaned enforcement—but two pairs are degraded and several automated bindings provide little information. The taxonomy pressure is visible in current truth: ZFS options and utility packages sit in Behavior, flake/source-tree rules sit in Architecture, and Ops combines configuration, transitions, repository commands, testing, and operator tooling.

The desired post-state replaces the roster with Service, Estate, Configuration, Lifecycle, and Governance. This is a bootstrap migration: Specbase resolves delta roots from the current `specbase/config.yaml`, while the stack enforces delivery order. The second member therefore remains proposal/design-only and explicitly blocked until this change is archived and the new roster becomes current truth.

The change must remain reviewable and valid before cutover while also producing a coherent post-cutover tree. It must not change the running homelab.

## Goals / Non-Goals

**Goals:**

- Make requirement placement predictable through five non-overlapping plane purposes and a deterministic decision order.
- Account for every current requirement with a keep, split, demote, or drop verdict.
- Produce a complete paired future tree with honest enforcement and stable pair-local IDs where meaning survives.
- Replace the roster, current tree, generated workflow guidance, review lenses, and routing policy as one consistency boundary.
- Preserve strong evidence while narrowing or retiring sources that prove only source shape, wrapper invocation, or helper existence.
- Leave every prefix coherent: the first stack member is complete and valid before the typed Estate registry begins.

**Non-Goals:**

- Introducing the typed Estate registry or generated graph checks; that is the next stack member.
- Changing NAS packages, accounts, service settings, host placement, deployment behavior, or runtime outcomes.
- Building a generic test compiler.
- Automating physical-site, disk-health, real-client, or recovery claims that remain honestly manual/review strength.
- Preserving incidental configuration as permanent truth merely because an existing check can evaluate it.

## Decisions

### D1. Planes classify assertion nature, locators classify homelab subject

The post-state roster is exactly:

1. **Service** — steady-state outcomes directly observed by a human, administrator, device, or client service.
2. **Estate** — nodes, roles, placement, dependencies, authorities, state/trust boundaries, and failure domains in the desired graph.
3. **Configuration** — selected realization values and mechanisms important enough that changing them requires a proposal.
4. **Lifecycle** — truths whose meaning depends on time, an event, or a transition.
5. **Governance** — the repository and machinery that declares, builds, tests, reviews, or deploys the estate.

Classification applies in Governance → Lifecycle → Service → Estate → Configuration order after compound claims are split. This order resolves the main overlaps: test machinery is Governance rather than Estate; post-reboot truth is Lifecycle rather than Service; workload placement is Estate rather than Configuration; internal listeners and ACL realization are Configuration rather than Service.

### D2. Security remains decomposed

A Security plane would recreate ambiguity because security assertions have different evidence and change clocks. Authorization outcomes are Service; identity/trust authority boundaries are Estate; product/group/ACL/certificate settings are Configuration; enrollment/rotation/revocation are Lifecycle; repository secret controls are Governance.

### D3. The migration uses a requirement-level manifest

`mapping.md` records all 32 current requirement IDs, verdict, destination pair/ID, enforcement disposition, and rationale. Requirements retain their pair-local ID when their meaning remains intact. Split claims retain the old ID for the principal surviving claim and receive new IDs for newly separated atoms. Spec IDs change because a cross-plane migration creates a new permanent identity and retires the old pair.

Low-value claims are explicitly dropped or demoted:

- Vim/Git enablement remains ordinary Nix configuration.
- Exact warning wording is implementation trivia; the safety setting remains Configuration truth.
- Make target/help existence is not a durable operational outcome.
- An unspecified update cadence is not verifiable current truth.

### D4. Future pairs are staged under current discoverable roots, then rebased atomically

Before cutover, the change stages complete future pair content beneath current-plane directories so the current-roster validator can discover and validate it:

| Bootstrap directory | Future directory | Stable future spec ID |
|---|---|---|
| `behavior/nas-capabilities` | `service/nas-capabilities` | `service.nas-capabilities` |
| `architecture/nas-storage` | `estate/nas-storage` | `estate.nas-storage` |
| `ops/nas-realization` | `configuration/nas-realization` | `configuration.nas-realization` |
| `ops/nas-transitions` | `lifecycle/nas-transitions` | `lifecycle.nas-transitions` |
| `agents/specbase` | `governance/specbase` | `governance.specbase` |
| `agents/nix-repository` | `governance/nix-repository` | `governance.nix-repository` |
| `agents/deployment-control` | `governance/deployment-control` | `governance.deployment-control` |
| `agents/testing-control` | `governance/testing-control` | `governance.testing-control` |
| `agents/operator-tooling` | `governance/operator-tooling` | `governance.operator-tooling` |
| `code-quality/enforcement-quality` | `governance/enforcement-quality` | `governance.enforcement-quality` |

The bootstrap location is transitional archive rationale, not permanent truth. During apply, the complete current post-state is prepared off-tree, the staged pairs are moved to their future roots without changing IDs, and `specbase/config.yaml` is replaced at the same cutover. The change is then revalidated under the new roster before archive.

### D5. Roster and lens replacement is atomic

`specbase/config.yaml` becomes the authoritative exact replacement roster. Each plane declares its purpose, enforcement flavor, and review lens. The review panel resolves scoped `service`, `estate`, `configuration`, `lifecycle`, and `governance` lenses plus the cross-cutting `enforcement` lens. Test-tree routing points to `governance.enforcement-quality`.

Generated repo-specific skills/prompts are regenerated after the config changes; changing config without regeneration is incomplete because generated guidance embeds the roster at generation time.

### D6. Evidence strength follows the assertion boundary

The change preserves the evidence ladder:

```text
static/eval -> closure build -> isolated VM -> live estate -> recovery drill
```

No layer claims the layer to its right. One execution may emit separate observations for several requirements, but a binding covers only the observations that establish its own requirement. Shared setup and whole-file exit status are not evidence.

### D7. Enforcement quality has three trust anchors

`governance/enforcement-quality` combines:

1. Deterministic conformance for assertion scope, target resolution, provenance, freshness, safety, and limitations.
2. Representative mutation/fault fixtures proving each reusable evidence family can fail for the intended reason.
3. Independent enforcement-lens review for semantic adequacy that automation cannot decide.

This stops the meta-test regress: no requirement says that a test is meaningful merely because another script exists or ran.

### D8. Estate evidence is honest before the registry exists

Current prose implies the SMB workload and ZFS pools belong to the NAS role, so `estate/nas-storage` records those current placement/state-ownership boundaries. Until the second stack member introduces typed graph evidence, deterministic configuration checks may support reconciliation but cannot prove the Estate claim. The pair therefore uses honest Estate review/manual limitations rather than a synthetic graph script.

### D9. Stack sequencing gates the second member

Specbase reports `introduce-typed-estate-registry` as blocked by this predecessor and refuses Apply instructions for it. Its proposal/design scope is retained now, but its `estate/*` and `governance/*` deltas and apply tasks are authored only after this change archives and the new roster is current truth. This is an enforced stack boundary, not missing work in this change.

## Enforcement design

### Service — NAS capabilities

- **Assertions/observations:** SMB clients enumerate and mount the intended shares; bounded fixtures round-trip and clean up; administrator SSH and non-interactive elevation succeed when safely exercised.
- **Harness/environment:** existing multi-node NixOS Samba VM plus live macOS SMB probe; evaluated account configuration supports Configuration only; a bounded live SSH probe or retained manual attestation supplies the Service residue.
- **Failure signal:** protocol transcript or command diagnostic identifies enumeration, mount, mutation, read, deletion, cleanup, transport, authentication, or elevation failure.
- **Boundary:** VM behavior does not prove Finder/macOS compatibility; evaluated accounts do not prove live authorization; one live probe is point-in-time evidence.

### Estate — NAS storage

- **Assertions/observations:** SMB workload and durable pool ownership resolve to the NAS role; no claim is made that Nix evaluation proves physical placement.
- **Harness/environment:** Estate review over Nix/host topology plus bounded live reconciliation (`hostname`, Samba process, pool identity/status) where available.
- **Failure signal:** review or reconciliation identifies an undeclared placement, owner, dependency, or mismatch.
- **Boundary:** physical hardware, cabling, and disk ownership remain human-observed until the typed registry and reconciliation sources exist.

### Configuration — NAS realization

- **Assertions/observations:** evaluated ZFS pool/import policy, stable host identity, compatible selected kernel/module closure, and administrator account policy match the curated requirements.
- **Harness/environment:** `nix eval`, closure builds, and generated configuration inspection through project-native tests; never source grep when final evaluated state exists.
- **Failure signal:** structured expected/observed value or derivation failure.
- **Boundary:** evaluation/build does not prove boot import, physical pool health, SSH access, or active-generation identity.

### Lifecycle — NAS transitions

- **Assertions/observations:** boot returns pools online without forced root import; deployment modes preserve their transition semantics; post-activation verification runs in the correct order and failures propagate honestly.
- **Harness/environment:** existing controlled deployment adapters for ordering/failure semantics, deployment-health live observations, and fenced manual boot/deploy evidence until safe transition automation exists.
- **Failure signal:** before/event/after record, generation identity, failed-unit diagnostics, pool state, nonzero transition result, and residue/rollback status.
- **Boundary:** fake adapters prove control flow only; point-in-time health does not prove the transition; manual evidence must identify host, generation, time, and result.

### Governance — Specbase, repository, deployment, testing, tooling

- **Assertions/observations:** roster/config/guidance/lenses agree; flake/host-module contracts and pins evaluate; deployment interface and overrides resolve; test stages/isolation/builders preserve their boundaries; operator tooling evaluates and builds across supported systems.
- **Harness/environment:** existing project-native tests, strict Specbase validation, evaluated flake outputs, closure checks, private-network NixOS tests, controlled runner fixtures, and tooling Bats suites.
- **Failure signal:** exact roster/lens/path/value/derivation/stage mismatch and retained diagnostic.
- **Boundary:** source-layout checks cover layout only; controlled adapters cover orchestration only; catalogue semantics remain review-strength.

### Governance — enforcement quality

- **Assertions/observations:** bindings are assertion-scoped; expected and observed sources are meaningfully independent; live checks record provenance/freshness/blast radius/cleanup; each reusable family has a representative defect fixture; qualitative adequacy receives independent review.
- **Harness/environment:** planned deterministic conformance over specs/enforcement metadata and evidence records, existing concrete safety fixtures, family-level mutation tests, cross-cutting enforcement lens.
- **Failure signal:** violation names requirement, binding, expected property, observed metadata or mutation result, and environment.
- **Boundary:** no deterministic rule fully proves semantic adequacy. The review binding remains first-class and may leave the pair degraded where automation would be hollow.

## Risks / Trade-offs

- **[Bootstrap artifacts validate under the old roster]** -> Keep future IDs and complete paired content, record the bootstrap-to-future path table, rebase before config replacement, and validate again under the new roster before archive.
- **[Atomic cutover leaves a half-migrated tree]** -> Build a complete scratch tree, run strict validation/coverage there, replace config and spec roots in one Git-visible operation, and keep rollback as a single revert.
- **[Requirement intent is lost while splitting]** -> Use `mapping.md` as a 32-row accounting manifest and review each source requirement against its destination before cutover.
- **[Pair proliferation]** -> Use one-level locators and cohesive common closure; do not add plane-root or enumerating parent pairs.
- **[Configuration becomes prose Nix]** -> Retain only decisions whose change deserves a proposal; explicitly drop incidental packages and warning wording.
- **[Estate is falsely automated]** -> Accept review/manual strength until the downstream typed registry provides real graph properties and live reconciliation.
- **[Good tests are discarded with weak bindings]** -> Judge evidence source-by-source; preserve strong protocol/VM/eval checks and narrow only their claimed coverage.
- **[Generated guidance drifts]** -> Regenerate and conformance-test skills/lenses immediately after the roster replacement.
- **[Downstream proposal appears incomplete]** -> Preserve its proposal/design as staged intent, rely on Specbase sequence gating, and author its plane deltas immediately after this change archives.

## Migration Plan

1. Capture baseline `specbase validate --strict`, `specbase coverage --json`, current pair inventory, requirement IDs, scenario IDs, binding IDs, and source targets.
2. Finalize `mapping.md`; review every current requirement and every binding for keep/split/demote/drop and destination.
3. Build a complete scratch `specbase-next/` tree with exactly the five new plane roots and all future spec/enforcement pairs. Preserve pair-local requirement/scenario IDs when meaning survives.
4. Rebase the change's staged bootstrap pairs to their future directories according to D4; retain future spec IDs and update only path-derived references.
5. Replace the roster in a scratch copy of `specbase/config.yaml`; regenerate the review lens set and repo-specific Specbase skills/prompts from that copy.
6. Run strict spec/change validation, coverage/orphan checks, STE lint where applicable, current project-native enforcement, and explicit discovery checks against the scratch tree. Confirm every pair is discovered, not merely parsable.
7. Atomically replace the live `specbase/config.yaml` roster and `specbase/specs/` tree, install regenerated instruments, and update test-quality routing.
8. Re-run status/instructions under the new roster; confirm this change's deltas now resolve as Service/Estate/Configuration/Lifecycle/Governance pairs.
9. Run strict validation and coverage on the live tree; require no unknown roots, incomplete pairs, stale bindings, broken targets, or unaccounted requirements. Degraded review/manual evidence is acceptable when honest and documented.
10. Validate the stack; confirm `introduce-typed-estate-registry` now resolves the new roster and is the next unfinished member.

Rollback is a single revert of the atomic cutover plus regenerated instruments. The running NAS and its Nix configuration are not changed, so no host rollback is required.
