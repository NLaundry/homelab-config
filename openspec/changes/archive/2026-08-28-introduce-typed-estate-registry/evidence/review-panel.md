# Estate registry review panel

## Deterministic gate

Before review, strict change/current validation, stack projection, focused six-test registry harness, all-system flake evaluation, Estate check derivation, routine project tests, and representative invalid fixtures passed.

## Lenses

- Estate: clean.
- Governance: one verified high and two medium findings; resolved and re-reviewed clean.
- Enforcement: seven medium/low findings across two passes; resolved and final re-review clean.
- Nix implementation review: one verified high plus medium/low findings; resolved and final re-review clean.
- Completeness critic: clean.
- Service, Configuration, and Lifecycle skipped because this change does not alter their truth.

## Findings and resolutions

1. **Typed schema forcing (high):** the module result could remain lazy. Production model/export now deep-force the complete typed configuration; unknown fields fail.
2. **One-way reconciliation (high/medium):** reconciliation now compares complete expected and observed relation sets in both directions and reports observed-only workload/state facts.
3. **Observation mutant fidelity (medium):** missing-fact mutants now evaluate a forced NixOS configuration through the production observation adapter; observed-only model mutants reuse production observations.
4. **Duplicate relationships (medium):** references are canonicalized before edge construction, duplicate state dependencies receive a diagnostic, edge IDs are unique, and the duplicate fixture graph mutation-tests canonicalization.
5. **Diagnostic stability (medium/low):** observed references are sorted; every invalid fixture must equal its exact full structured oracle.
6. **Diff coverage (medium):** node addition/removal, reorder, placement move, and ownership change fixtures assert every meaningful and empty bucket.
7. **Routine discovery (medium):** the default harness now includes `tests/estate/*.bats`; the routine harness passes 51 tests.
8. **Limitations (low):** tests assert exact declared-model, evaluated, and physical limitation identifiers.
9. **Failed-check diagnostics (medium/low):** check failure logs print production graph/violations, actual and expected fixture arrays, diffs, reconciliation, and both mutants before exiting.
10. **Retained evidence freshness (low):** final evidence is regenerated after the completed implementation and records the final implementation digest.

Panel findings remain review-strength and do not replace deterministic gates.
