## Context

Estate is now the permanent home for sites, hosts, roles, placement, dependencies, state ownership, authorities, trust boundaries, and failure domains. The current `estate/nas-storage` pair records the file-sharing workload and storage-pool ownership on the NAS, but its strongest evidence is review/reconciliation because the repository has no machine-readable Estate model.

Topology is implicit across `flake.nix`, `hosts/nas/*`, service modules, inventory, and tests. Nix can evaluate final system configuration, but it does not expose typed homelab concepts such as site, logical host role, workload placement, durable state ownership, or workload-to-state dependency. Parsing Nix source is unsound because module imports, functions, conditionals, priorities, laziness, and merges determine the evaluated result.

The predecessor stack member is archived. Estate and Governance roots are now current, so this change can carry complete paired deltas and implementation tasks.

## Goals / Non-Goals

**Goals:**

- Create a small typed evaluated source of truth for what exists, where workloads run, and which host owns durable state.
- Keep Estate relationships separate from Configuration implementation detail.
- Export deterministic normalized graph data for inspection, diffing, and later affected-host/build/test selection.
- Enforce universal graph properties over the complete declared model rather than one script per node.
- Demonstrate checker sensitivity through invalid fixtures with exact diagnostic codes and subjects.
- Seed only Estate truth already established by `estate/nas-storage`.
- Improve NAS Estate evidence without pretending a declared graph or evaluated service option proves physical reality.

**Non-Goals:**

- Generating NixOS host/service configuration from the graph.
- Generating Service or Lifecycle expectations/tests.
- Modeling packages, versions, listeners, addresses, accounts, mounts, ACLs, schedules, firewall rules, secrets, or runtime health.
- Adding networks, endpoints, authorities, replicas, failure domains, gateways, or trust zones before a concrete requirement needs them.
- Building a CMDB or proving physical site, power, cabling, disk, or real-client facts.

## Decisions

### D1. The initial graph has four node kinds and four derived relationship kinds

The schema contains `site`, `host`, `workload`, and `state` records. Records declare:

- each host's site,
- each workload's host placements,
- each workload's consumed state,
- each state node's authoritative owners.

Normalization derives `located-at`, `runs`, `consumes`, and `owns` edges. The relationship vocabulary is not independently editable, so illegal edge kinds are unrepresentable. New node or relationship kinds require later proposals.

### D2. Registry identity is logical, stable, and namespaced on export

Registry records use safe attrset keys such as `home`, `nas`, `file-sharing`, `mediaBin`, and `smolBoy`. Nix attrsets make duplicate keys unrepresentable. The normalized graph exports namespaced IDs such as `site:home` and `workload:file-sharing`, preventing cross-kind collisions.

IDs represent stable logical roles, not labels, runtime hostnames, addresses, or physical serial numbers. A replacement machine that assumes the same logical NAS role may preserve `host:nas`; a future requirement for physical identity or redundancy must add an explicit Estate concept.

### D3. Nix module types validate shape; pure Nix validates semantics

A `lib.evalModules` schema validates record shape, required fields, enums, and safe identifiers. Workload placements and state owners are lists so zero/multiple cardinality defects remain representable for semantic fixtures. A pure Nix library normalizes the evaluated registry and returns structured violations for:

- unknown site/host/state references,
- zero or multiple workload placements,
- zero or multiple authoritative state owners,
- dangling references after node removal.

Validators return data instead of boolean-only assertions. A thin check derivation fails when production violations are non-empty and retains JSON diagnostics.

### D4. The registry is authoritative for Estate declaration, not observed reality

`nix/estate/registry.nix` is the canonical desired Estate declaration. Existing NixOS modules remain Configuration realization. A separate reconciliation adapter compares selected independent evaluated observations with the graph—for example, the file-sharing placement with evaluated Samba enablement and state ownership with evaluated ZFS pool selection.

The graph is not generated from those observations. This expected/observed split avoids tautology and reports drift. Evaluation still cannot prove physical workload/disk placement or exclusive authority.

### D5. Normalized export is a stable machine interface

The flake exposes `lib.estateGraph`, a JSON-safe attrset containing `schemaVersion`, sorted nodes, and sorted edges. It excludes functions, derivations, secrets, packages, arbitrary NixOS options, and declaration order.

A check derivation writes the normalized graph and violations as JSON artifacts and prints a structured failure summary before exiting nonzero. The interface is read with `nix eval --json .#lib.estateGraph`; no unknown custom top-level flake output is introduced.

### D6. Properties are universal and diagnostic

Initial properties are:

1. Every ID is safe and unique within its node kind; namespaced export IDs are globally unique.
2. Every host site, workload placement/state dependency, and state owner reference resolves to the allowed node kind.
3. Every workload has exactly one host placement.
4. Every durable state node has exactly one authoritative host owner.
5. Removing a referenced host exposes the resulting placement/ownership references as violations.

Every violation carries `code`, `subject`, `expected`, and `observed`. No per-node generated shell checks are created.

Failure-domain and replica properties are deferred because this schema cannot express them honestly. Duplicate-key fixtures are also omitted because Nix attrsets cannot represent them.

### D7. Invalid fixtures prove family-level sensitivity

Independent fixture registries exercise:

- missing and multiple workload placements,
- unknown site, host, and state references,
- duplicate state dependencies and unsafe logical IDs,
- ownerless and multiply owned state,
- host removal leaving workload/state references dangling.

Tests assert exact sorted violation arrays—including code, subject, expected property, and observed references—not merely nonzero exit. Mutation evidence is required for the reusable graph family after introduction or a material checker rewrite, not once per Estate requirement.

### D8. Diffs operate on normalized identity

The pure diff function compares normalized node/edge maps and emits sorted `added`, `removed`, and `changed` groups. Current normalized records contain identity fields only, so placement and ownership changes are represented as one relationship removal and one addition; `changed` groups remain empty until a future schema introduces non-identity payload. Declaration reorder produces an empty diff. Node add/remove fixtures exercise every currently meaningful bucket. Presentation/source movement does not become an Estate change.

### D9. The registry does not generate expected Service behavior

The graph may later select affected host builds and existing regression suites. It does not infer share names, authorization matrices, DNS answers, protocol success, or recovery objectives. Specs and independent policy fixtures remain the expected oracle for Service and Lifecycle evidence.

### D10. Plane ownership remains split

- `estate/model` owns universal desired-graph integrity.
- `estate/nas-storage` owns current NAS workload placement and storage ownership.
- `governance/estate-registry` owns the repo instrument: typed schema, export, validator, diff, fixtures, check integration, and reconciliation adapter.

The instrument belongs to Governance rather than Configuration because it controls IaC truth rather than selecting a runtime product.

## Enforcement design

### Typed registry and normalized export

- **Assertions/observations:** valid records type-check; export contains only schema version, sorted nodes/edges, stable namespaced IDs, and selected Estate fields.
- **Harness/environment:** Nix module evaluation, `nix eval`, and project flake checks on supported evaluators.
- **Failure signal:** type error or structured export mismatch naming the record/field.
- **Boundary:** shape validity does not prove semantic correctness or live topology.

### Graph properties

- **Assertions/observations:** the complete evaluated production graph satisfies reference and cardinality properties.
- **Harness/environment:** pure Nix property library forced through a flake check and queried by a Bats harness.
- **Failure signal:** exact `code`, `subject`, `expected`, and `observed` JSON; production check fails on non-empty violations.
- **Boundary:** properties prove declared-model integrity only.

### Mutation/fault sensitivity

- **Assertions/observations:** every invalid fixture emits its intended code/subject set while the valid fixture remains clean.
- **Harness/environment:** fixture registries are independent values passed to the same production validator.
- **Failure signal:** missing, extra, or wrong diagnostic fails the Bats/Nix check.
- **Boundary:** fixtures prove selected defect classes, not absence of validator bugs.

### Normalized graph diff

- **Assertions/observations:** reorder-only input is empty; node add/remove and placement/ownership remove-add pairs affect only intended buckets; unrelated and current `changed` buckets remain empty.
- **Harness/environment:** before/after fixtures use the production normalizer/diff library.
- **Failure signal:** expected and observed structured diff differ.
- **Boundary:** describes declared Estate change, not Configuration or runtime drift.

### NAS Estate reconciliation

- **Assertions/observations:** graph declares Home → NAS, NAS → file-sharing, NAS → both state nodes, and file-sharing → both state nodes; independently evaluated NAS facts do not contradict those declarations.
- **Harness/environment:** pure reconciliation adapter plus retained Estate review of physical limitations.
- **Failure signal:** mismatch names graph subject, expected relation, and observed evaluated fact.
- **Boundary:** service enablement and pool selection do not prove physical placement, health, cabling, or exclusive authority.

## Risks / Trade-offs

- **[Registry duplicates Configuration]** -> Restrict schema to Estate nodes/relationships and reconcile against independently evaluated realization.
- **[Graph agrees only with itself]** -> Label properties as declared-model evidence and retain independent evaluated/live/review boundaries.
- **[Schema grows into a CMDB]** -> Require a proposal and enforcing use case for every new kind; start with four.
- **[Cardinality lists permit invalid declarations]** -> Keep invalid states representable for structured diagnostics; production check rejects them.
- **[Pure Nix diagnostics are unreadable]** -> Return stable records and assert exact codes/subjects through Bats.
- **[Central registry adds an Estate edit]** -> Register only topology/ownership changes that should require an Estate update; exclude incidental realization.
- **[Logical identity hides hardware replacement]** -> Add physical/failure-domain nodes only when a real requirement demands them.
- **[Test selection overreaches]** -> Export graph/diff data only; do not claim selected tests prove changed requirements.

## Migration Plan

1. Author paired deltas for `estate/model`, `estate/nas-storage`, and `governance/estate-registry` under current roots.
2. Implement typed schema, registry, normalization, validation, diff, and reconciliation libraries under `nix/estate/`.
3. Seed Home, NAS, file-sharing, `mediaBin`, and `smolBoy` from current Estate truth.
4. Expose `lib.estateGraph` and a flake check that retains normalized graph/diagnostic artifacts.
5. Add valid, cardinality, unknown-reference, host-removal, reorder, placement-move, and ownership-change fixtures.
6. Add project-native Bats assertions for export, diagnostics, diff, and reconciliation.
7. Update `estate/nas-storage` enforcement and record explicit physical/runtime limitations.
8. Run strict Specbase validation/coverage, Nix evaluation/checks, routine harness, mutation fixtures, and Estate/Governance/Enforcement review.
9. Record future extensions as separate proposals only when concrete requirements arise.

Rollback removes the registry/export/check surfaces and restores review-backed NAS Estate enforcement. It does not alter the running NAS.
