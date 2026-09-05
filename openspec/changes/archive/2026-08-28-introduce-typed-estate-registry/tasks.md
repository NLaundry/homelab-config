## 1. Implement the typed Estate model

- [x] 1.1 Implement `nix/estate/schema.nix` with typed site, host, workload, and state records; keep Configuration fields and future node kinds out.
- [x] 1.2 Implement `nix/estate/registry.nix` with Home, NAS, file-sharing, `mediaBin`, and `smolBoy` declarations matching current Estate truth.
- [x] 1.3 Implement pure normalization that exports schema version, sorted namespaced nodes, and sorted derived `located-at`, `runs`, `consumes`, and `owns` edges.
- [x] 1.4 Implement pure semantic validation for reference resolution, workload placement cardinality, state ownership cardinality, and dangling host removal with stable structured diagnostics.
- [x] 1.5 Implement normalized graph diff for node/edge additions, removals, and changes with declaration-order independence.
- [x] 1.6 Implement bounded NAS reconciliation that compares declared placement/ownership with independently evaluated Samba enablement and selected ZFS pools without claiming physical proof.
- [x] 1.7 Expose `lib.estateGraph` and a project-native Estate check derivation without changing NixOS runtime configuration.

## 2. Deliver registry evidence

- [x] 2.1 Add independent valid, zero/multiple placement, unknown-reference, zero/multiple owner, host-removal, reorder, placement-move, and ownership-change fixtures.
- [x] 2.2 Implement `tests/estate/registry.bats` to assert schema/export boundaries, exact diagnostic codes/subjects, normalized diffs, and reconciliation results through evaluated Nix.
- [x] 2.3 Integrate the Estate registry source into the routine harness and flake checks; ensure failures retain normalized graph and violation artifacts.
- [x] 2.4 Add exact observation declarations for every new automated binding to `tests/specbase/enforcement-observations.json` and keep semantic adequacy with the Enforcement lens.
- [x] 2.5 Execute Nix evaluation, Estate flake checks, focused registry Bats, and representative mutants through their native harnesses.
- [x] 2.6 Record commands, implementation digest, results, and declared-model/evaluated/live/physical limitations under this change's evidence directory.

## 3. Activate paired enforcement

- [x] 3.1 Verify `estate/model`, `estate/nas-storage`, and `governance/estate-registry` bindings resolve to implemented sources with exact requirement coverage.
- [x] 3.2 Run strict change/current validation, coverage, orphan detection, and explicit discovery; require no broken, stale, hanging, incomplete, unknown-root, or unlensed claims.
- [x] 3.3 Confirm no enforcement target is retired by this change; preserve the existing Estate review source for physical-placement residue.

## 4. Review and delivery readiness

- [x] 4.1 Run Estate, Governance, and Enforcement review lenses over the staged change; refute high findings and resolve actionable results.
- [x] 4.2 Run full project lint/routine tests and selected safe evaluation/live reconciliation needed by the changed evidence families.
- [x] 4.3 Record rollback as removal of registry/export/check surfaces and restoration of review-backed NAS Estate enforcement; confirm no host rollback is needed.
