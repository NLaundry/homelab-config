## Context

The predecessor change introduces Estate as the permanent home for sites, hosts, roles, workload placement, dependencies, state/trust boundaries, authorities, and failure domains. Its first Estate pair records the current file-sharing workload and storage-pool ownership on the NAS, but enforcement is initially review/reconciliation strength because the repository has no machine-readable estate model.

Current topology is implicit across `flake.nix`, `hosts/nas/*`, service modules, Ansible inventory, and test constants. Nix can evaluate final system configuration, but those values do not expose typed homelab concepts such as site, host role, workload, durable state, ownership, or failure domain. Parsing Nix source is unsound because modules are functions and imports, priorities, conditionals, overlays, laziness, and merges determine the final result.

This change follows `adopt-homelab-native-spec-planes` in a finite stack. Specbase reports this member as blocked and refuses Apply instructions until the predecessor is archived; its `estate/*` and `governance/*` deltas are authored against the new roster once that predecessor becomes current truth.

## Goals / Non-Goals

**Goals:**

- Create a small typed, evaluated source of truth for what exists, where workloads run, and who owns durable state.
- Keep Estate relationships separate from Configuration implementation detail.
- Export deterministic normalized graph data that machines can inspect, diff, and use for later build/test selection.
- Enforce high-leverage universal properties over the complete declared graph rather than one shell check per node.
- Demonstrate checker sensitivity through representative invalid graph fixtures.
- Seed only current NAS truth already established by the predecessor.
- Improve `estate/nas-storage` enforcement without pretending a declared graph proves physical reality.

**Non-Goals:**

- Generating NixOS host configurations or service modules from the graph.
- Generating protocol tests, live probes, or expected Service outcomes.
- Modeling packages, versions, listeners, addresses, users/groups, mounts, firewall rules, ACL syntax, schedules, or secrets.
- Building a complete CMDB or modeling transient runtime state.
- Adding networks, endpoints, authorities, replicas, gateways, or trust zones before a concrete requirement needs them.
- Proving physical site, power, cabling, ISP, disk, or real-client facts through evaluation alone.

## Decisions

### D1. The initial graph has four node kinds and four relationship kinds

The first schema contains:

- `site`
- `host`
- `workload`
- `state`

It permits:

- host `located-at` site,
- host `runs` workload,
- workload `consumes` state,
- host `owns` state.

This is enough to express the Home site, NAS host/role, file-sharing workload, and `mediaBin`/`smolBoy` storage ownership. Additional kinds require later proposals so the registry grows from real questions rather than speculative completeness.

### D2. Registry identity is logical and stable

Node IDs use stable role-oriented names rather than presentation labels, runtime hostnames, or addresses. Renaming a display label does not change graph identity. A replacement machine that assumes the same host role may preserve the logical host node; adding/removing a physical failure boundary requires an Estate change.

Relationships reference node IDs and allowed endpoint kinds. Referential and cardinality validation runs over the complete graph after typed shape evaluation.

### D3. Nix module types validate shape; pure Nix validates graph semantics

The NixOS/module type system validates node structure, required fields, enums, and safe identifiers. A pure Nix library normalizes nodes/edges and returns structured violations for semantic properties such as unknown references, illegal edge kinds, duplicate placement, and ownerless durable state.

Validators return data rather than relying only on `assert`/`throw`; a thin flake check forces evaluation and fails when violations are non-empty. This keeps the oracle in typed graph rules and produces useful diagnostics without source grep or shell-coded graph logic.

A runtime language is unnecessary for this initial graph because validation, normalization, and diffing are pure transformations with no network, clock, or filesystem effects beyond ordinary Nix evaluation/build plumbing.

### D4. The registry is authoritative for Estate declaration, not observed reality

A central Nix declaration is the canonical desired Estate graph. Existing host/service configuration remains the Configuration realization. Selected reconciliation checks compare independent evaluated observations with the graph—for example, a declared NAS file-sharing workload may be compared with the evaluated service enablement and host role—but the graph is not generated from those same observations.

This intentional expected/observed split avoids tautology. It also means a placement change updates Estate declaration and Configuration realization separately when both genuinely change; enforcement reports drift between them.

### D5. Normalized export is a public machine interface for repository tooling

The flake exposes a JSON-safe projection containing a schema version, sorted nodes, sorted edges, and stable identifiers. It excludes functions, derivations, secrets, package values, arbitrary NixOS options, and source-order noise.

Normalization gives deterministic equality and graph diffs. The change emits structured additions, removals, and changed relationships; it does not treat textual Nix movement as topology change.

### D6. Property checks are universal and diagnostic

Initial properties are:

1. Every node ID is unique and type-valid.
2. Every edge references existing nodes of allowed endpoint kinds.
3. Every workload has exactly one host placement.
4. Every durable state node has exactly one authoritative host owner.
5. Removing a host from a proposed graph cannot leave a workload placement or state owner dangling.
6. Failure-domain separation, once a relation is declared, cannot be claimed when both graph paths resolve to the same domain.

The sixth property may be exercised through a future-shaped fixture before replicas are seeded, but no unused production node kind is added solely to satisfy the fixture. If the final minimal schema cannot express the property honestly, the fixture and requirement are deferred rather than simulated through irrelevant fields.

Each violation contains a stable diagnostic code, subject ID, expected property, and observed references. One property family covers all registered nodes; no generated per-node shell scripts are created.

### D7. Mutation fixtures prove family-level sensitivity

Valid and invalid fixtures exercise:

- duplicate workload placement,
- unknown host/site/state references,
- durable state without an owner,
- duplicate node identity,
- host removal leaving dangling relationships,
- same-domain separation when that relation exists.

The fixture test asserts the exact diagnostic code and subject, not merely nonzero exit. Mutation evidence is required once for the reusable graph family and after a material checker rewrite, not once per Estate requirement.

### D8. The registry does not generate expected Service behavior

The normalized graph may later select affected host builds and existing regression suites. It does not infer share names, authorization matrices, DNS answers, recovery objectives, or protocol success from realization. Specbase requirements or independent policy fixtures remain the expected oracle for Service and Lifecycle evidence.

### D9. Plane ownership is split between Estate and Governance

- `estate/model` owns universal truths about the desired graph.
- Existing `estate/nas-storage` owns the actual NAS placement and storage-ownership facts.
- `governance/estate-registry` owns the repo instrument: typed schema, normalized export, checker, diff behavior, fixtures, and evidence interface.

The registry is not put in Configuration because it is part of the IaC control system, not a selected runtime product. The graph contents remain Estate truth even though Nix realizes them.

## Enforcement design

### Typed registry and normalized export

- **Assertions/observations:** valid node records type-check; normalized export contains only the declared schema/version/nodes/edges; ordering is stable; secrets/functions/derivations/configuration detail are absent.
- **Harness/environment:** Nix module evaluation and flake checks on supported evaluation systems.
- **Failure signal:** Nix type error or structured export mismatch identifying field and node.
- **Boundary:** type validity does not prove referential integrity, semantic correctness, or live topology.

### Graph properties

- **Assertions/observations:** complete evaluated graph satisfies uniqueness, allowed-reference, single-placement, state-owner, dangling-removal, and applicable failure-domain properties.
- **Harness/environment:** pure Nix property library forced through a flake check; valid current graph plus focused fixtures.
- **Failure signal:** structured violation code, subject, expected property, and observed edges; flake check fails when production violations are non-empty.
- **Boundary:** checks the desired model only; it does not establish that hosts, workloads, disks, or sites physically match it.

### Mutation/fault sensitivity

- **Assertions/observations:** every representative invalid fixture produces the intended violation code and subject, while the valid fixture remains clean.
- **Harness/environment:** Nix fixture evaluations independent of the production graph values.
- **Failure signal:** missing, extra, or wrong diagnostic causes the fixture check to fail.
- **Boundary:** fixtures prove selected defect classes, not the absence of bugs in the checker.

### Normalized graph diff

- **Assertions/observations:** equivalent graphs with different declaration order produce no diff; a workload move reports one placement-edge removal and one addition; ownership changes are distinguished from presentation changes.
- **Harness/environment:** before/after Nix fixtures evaluated through the pure diff library.
- **Failure signal:** expected and observed structured diff differ, with normalized node/edge output retained.
- **Boundary:** diff describes declared Estate change, not implementation or runtime drift.

### NAS Estate reconciliation

- **Assertions/observations:** seeded graph declares Home → NAS, NAS → file-sharing workload, NAS → `mediaBin`/`smolBoy` ownership, and file-sharing → both state nodes; selected evaluated host facts do not contradict those declarations.
- **Harness/environment:** graph property check plus bounded comparison with independently evaluated host/service facts; Estate review records physical limitations.
- **Failure signal:** graph violation or reconciliation mismatch names the node/edge and observed Nix fact.
- **Boundary:** process enablement does not prove real workload placement, and evaluated pool names do not prove disk ownership or health.

## Risks / Trade-offs

- **[Registry duplicates Nix configuration]** -> Restrict it to Estate nodes/edges, exclude Configuration fields, and reconcile rather than derive expected and observed from one value.
- **[Graph agrees only with itself]** -> Label property evidence as declared-model conformance and add selected independent evaluated/live reconciliation plus honest review limitations.
- **[Schema grows into a CMDB]** -> Require a proposal and enforcing use case for every new node/edge kind; start with four of each.
- **[Pure Nix diagnostics are unreadable]** -> Return structured violation records, export JSON-safe results, and assert exact diagnostic codes in fixtures.
- **[Central registry becomes a second edit for every change]** -> Treat Estate changes as exactly the changes that should update the graph; do not register incidental Configuration details. Later tooling may consume the graph to reduce duplicate placement declarations.
- **[Logical host identity hides hardware replacement]** -> Model role identity separately from future physical/failure-domain nodes when a real replacement or redundancy requirement demands it.
- **[Failure-domain claim is premature]** -> Defer production schema/requirements that cannot be expressed by current estate truth; fixtures must not justify speculative model growth.
- **[Test selection overreaches]** -> Export affected node/edge data only; do not automatically claim that selected tests prove the changed requirements.
- **[Stack member authored against stale roster]** -> Stop after proposal/design now; author specs, enforcement, and tasks only after the predecessor archives and CLI instructions expose Estate/Governance roots.

## Migration Plan

1. Apply and archive `adopt-homelab-native-spec-planes`; confirm `specbase status` for this change resolves the Estate and Governance roots and the stack names this member as next.
2. Re-run CLI instructions and author `estate/model`, `governance/estate-registry`, and any necessary paired update to `estate/nas-storage` under the resolved post-migration paths.
3. Define the minimal typed registry and pure validation/normalization/diff libraries without connecting them to runtime service generation.
4. Seed Home, NAS, file-sharing, `mediaBin`, and `smolBoy` from current Estate truth.
5. Export the normalized graph as a JSON-safe flake interface and add production graph properties.
6. Add valid, invalid, reorder-only, placement-move, and ownership-change fixtures; assert exact structured diagnostics/diffs.
7. Add selected independent reconciliation against evaluated NAS/service facts and document physical/runtime limitations.
8. Integrate graph/property/mutation checks into the project-native Nix check surface and pair them assertion-specifically in enforcement.
9. Run strict Specbase validation/coverage, Nix evaluation, flake checks, mutation fixtures, and Estate/Enforcement review.
10. Record future extensions—networks, endpoints, authorities, replicas, gateways, trust zones, affected-test selection—as separate proposals only when concrete requirements arise.

Rollback removes the registry/export/check surface and restores the preceding review-backed Estate enforcement. It does not alter the running NAS.
