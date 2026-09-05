## Why

Estate truth now states what exists, what runs where, and which host owns durable state, but those relationships remain prose and scattered Nix facts. A small typed Nix registry makes the desired Estate graph deterministic, queryable, diffable, and enforceable without copying full NixOS configuration into specs.

This is the second member of `homelab-native-governed-spec-planes-1e6a11e0`. Its predecessor, `adopt-homelab-native-spec-planes`, is archived and the new roster is current truth.

## What Changes

- Introduce a minimal typed Nix Estate registry with four node kinds:
  - sites,
  - hosts,
  - workloads,
  - durable state.
- Represent four relationships:
  - host located at site,
  - host runs workload,
  - workload consumes state,
  - host owns state.
- Seed the current Estate with the Home site, NAS role, file-sharing workload, and `mediaBin`/`smolBoy` durable state.
- Export a normalized JSON-safe graph from evaluated Nix. Do not parse Nix source or serialize arbitrary NixOS configuration.
- Enforce universal graph properties:
  - every reference resolves to an allowed node kind,
  - every workload has exactly one host placement,
  - every durable state node has exactly one authoritative host owner,
  - removing a referenced host produces a dangling-reference violation rather than an apparently valid graph.
- Return structured violations with stable codes, subjects, expected properties, and observed references.
- Produce normalized graph diffs for node/relationship additions and removals, representing placement or ownership changes as scoped remove/add pairs without source-order noise.
- Add invalid fixtures for unsafe logical IDs, zero/multiple workload placement, unknown references, duplicate state dependencies, zero/multiple state ownership, and dangling host removal.
- Reconcile selected graph facts against independently evaluated host configuration where a meaningful observation exists; label declared-model and physical limitations honestly.
- Expose graph data for later affected-host/build/test selection without generating tests in this change.
- Keep packages, versions, listeners, addresses, firewall rules, users/groups, mounts, ACLs, schedules, and generated service configuration outside the Estate graph.
- Defer networks, endpoints, authorities, replicas, failure domains, gateways, and trust zones until concrete Estate requirements need them.

## Planes

### Estate

- `estate.model`: universal desired-graph integrity—typed logical entities, valid references, unique workload placement, and explicit authoritative state ownership (new).
- `estate.nas-storage`: existing NAS placement and pool-ownership truth receives graph and reconciliation evidence without changing its durable meaning (modified enforcement).

### Governance

- `governance.estate-registry`: the repo-owned typed Nix schema, normalized export, property checker, graph-diff contract, invalid fixtures, and bounded reconciliation interface (new).

No Service, Configuration, or Lifecycle truth changes: client capabilities, selected NAS realization, and boot/deployment transitions remain unchanged.

## Enforcement intent

| Covered truth | Type | Source | Intended proof |
|---|---|---|---|
| Typed Estate entities | `static-analysis` | evaluated registry/property source | The production registry evaluates only the four selected logical node kinds with stable safe IDs. |
| References resolve | `static-analysis` | evaluated graph property checker | Every derived relationship targets an existing allowed node kind and violations name the exact subject/reference. |
| Workload placement is unique | `static-analysis` | evaluated graph property checker | Every workload has exactly one host placement; zero and multiple placements fail with stable diagnostics. |
| Durable state has one owner | `static-analysis` | evaluated graph property checker | Every durable state node has exactly one authoritative host owner; zero and multiple owners fail. |
| Registry is normalized and exportable | `test` | Nix evaluation plus Bats assertions | Valid registry input evaluates to sorted JSON-safe nodes/edges with a schema version and no Configuration detail. |
| Checker detects representative faults | `test` | independent invalid fixtures | Known ID, reference, duplicate-dependency, placement, ownership, and dangling-removal mutants fail with exact structured violations. |
| Graph diff is diagnostic | `test` | normalized before/after fixtures | Reordering is empty; node add/remove and placement/ownership remove-add pairs report only intended identities. |
| NAS placement and pool ownership | `static-analysis` + `review` | seeded graph, evaluated reconciliation, Estate lens | Registry output matches current NAS Estate truth without claiming evaluation proves physical reality. |

## Impact

- New `nix/estate/` schema, registry, normalization, validation, diff, reconciliation, and fixture surfaces.
- New flake library graph output and project-native check derivation.
- New Estate registry harness tests and structured execution evidence.
- Existing `estate/nas-storage` enforcement gains evaluated graph/reconciliation sources and retains physical limitations.
- No runtime NixOS service setting, package, firewall rule, account, mount, pool, host placement, or deployed generation changes.
