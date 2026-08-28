## Why

After the five-plane migration, Estate truth will state what exists, what runs where, what owns durable state, and which dependencies and failure domains apply—but those relationships will still be prose and scattered Nix facts. A small typed Nix registry can make the desired estate graph deterministic, queryable, diffable, and enforceable without turning specs into a copy of full NixOS configuration.

This is the second member of `homelab-native-governed-spec-planes-1e6a11e0` and requires `adopt-homelab-native-spec-planes` to be applied and archived first.

## What Changes

- Introduce a minimal typed Nix Estate registry for four initial node kinds:
  - sites,
  - hosts,
  - workloads,
  - durable state.
- Introduce four initial relationships:
  - host located at site,
  - host runs workload,
  - workload consumes state,
  - host owns state.
- Seed the current estate with the Home site, NAS role/host, file-sharing workload, and `mediaBin`/`smolBoy` durable state represented by the preceding Estate specs.
- Export a normalized, JSON-safe graph from evaluated Nix. Do not parse Nix source and do not attempt to serialize arbitrary NixOS configuration.
- Add high-value graph properties:
  - every reference resolves,
  - every workload has exactly one placement,
  - every durable state node has exactly one authoritative owner,
  - node IDs are unique,
  - removing a host cannot leave dangling workloads or state ownership,
  - replicas, when later introduced, cannot claim separation while sharing a declared failure domain.
- Produce structured violations and normalized graph diffs rather than boolean-only or grep-based failures.
- Add representative invalid graph fixtures proving the checker rejects duplicate placement, unknown references, ownerless state, duplicate identity, dangling removal, and false failure-domain separation.
- Reconcile selected graph facts against independently evaluated host configuration where a meaningful observation exists; label model-only and physical limitations honestly.
- Make graph output available to later tooling for affected host-build and regression-test selection, but do not build automatic test generation in this change.
- Keep packages, versions, listeners, firewall rules, users/groups, mount options, and generated service configuration outside the Estate graph.

## Planes

### Estate

- `estate.model`: universal integrity rules for the desired graph—valid nodes and references, unique workload placement, explicit state ownership, and honest failure-domain relationships (new).
- `estate.nas-storage`: current NAS file-sharing placement and pool ownership become registry-backed and graph-enforced without changing their durable meaning (modified enforcement; requirements remain semantically unchanged).

### Governance

- `governance.estate-registry`: the repo-owned typed Nix registry, normalized export, property checker, graph-diff contract, mutation fixtures, and evidence interface conform to the Estate model without parsing source or leaking Configuration detail (new).

No Service, Configuration, or Lifecycle truth changes: users receive the same capabilities, selected NAS realization stays the same, and no boot/deploy/recovery transition changes.

## Enforcement intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| Graph references resolve | `static-analysis` | evaluated graph property checker | Every relationship targets an existing node of an allowed kind and reports the exact invalid edge. |
| Workload placement is unique | `static-analysis` | evaluated graph property checker | Every workload resolves to exactly one declared host. |
| Durable state has one owner | `static-analysis` | evaluated graph property checker | Every durable state node resolves to exactly one authoritative host owner. |
| Failure-domain claims are honest in the model | `static-analysis` + `review` | graph checker plus Estate lens | Declared separation is rejected when graph paths resolve to the same domain; physical independence remains review/manual residue. |
| Registry is typed and exportable | `test` | Nix module/evaluation checks | Valid registry input evaluates to a normalized JSON-safe graph; malformed node shapes fail type validation. |
| Checker detects representative faults | `test` | invalid graph fixtures | Known duplicate placement, unknown reference, ownerless state, duplicate identity, dangling removal, and same-domain replica mutants fail with the intended diagnostic code. |
| Graph diff is diagnostic | `test` | normalized before/after fixtures | Placement and ownership changes report added, removed, and changed nodes/edges without source-order noise. |
| NAS placement and pool ownership | `static-analysis` + `review` | seeded evaluated graph and bounded reconciliation | Registry output matches declared NAS Estate truth; no claim is made that the graph alone proves physical reality. |

## Impact

- New typed Nix estate data/module surface and normalized graph flake output.
- New graph/property and graph-diff test fixtures integrated into project-native checks.
- Existing NAS Estate enforcement gains evaluated graph evidence; Service, Configuration, and Lifecycle enforcement remains unchanged.
- No runtime NixOS service setting, package, firewall rule, account, mount, pool, or host placement is intentionally changed.
- Plane-specific specs, enforcement, and implementation tasks are intentionally staged until the predecessor archives; Specbase stack sequencing reports this member as blocked and refuses Apply instructions in the meantime.
