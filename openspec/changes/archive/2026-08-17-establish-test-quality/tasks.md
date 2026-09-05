## 1. Test-quality truth

- [x] 1.1 Complete the remaining default-builder VM execution task in `establish-testing-operations` before applying this change.
- [x] 1.2 Add the `code-quality.testing` pair with atomic rules for production paths, defect sensitivity, bounded synchronization, run-scoped state, order independence, live cleanup, residue, and diagnostics.
- [x] 1.3 Review the pair against copied-logic, self-fulfilling-oracle, partial-assertion, fixed-sleep, shared-state, and failed-cleanup counterexamples.

## 2. Advisory review routing

- [x] 2.1 Update the review-panel instrument so changed files beneath `tests/**` select the Code-quality lens with `code-quality.testing` as policy while preserving normal affected-pair routing.
- [x] 2.2 Extend `tests/agents/specbase-instruments.sh#test-quality-routing` with controlled added, modified, renamed, deleted, and non-test path fixtures that fail on missing or over-broad routing.
- [x] 2.3 Link the `agents.review-panel` compact binding to the routing conformance selector and execute it through its native command harness.
- [x] 2.4 Confirm the panel remains read-only, advisory, and non-gating after the routing change.

## 3. Advisory quality evidence

- [x] 3.1 Exercise the enforcement lens procedure over one hollow current binding and one defect-sensitive controlled regression, recording why each fails or passes.
- [x] 3.2 Exercise the Code-quality lens procedure over representative synchronization, state-isolation, cleanup, and diagnostic examples.
- [x] 3.3 Confirm the compact Code-quality bindings cover requirements only and resolve to the configured `enforcement` and `code-quality` lenses.

## 4. Validation and handoff

- [x] 4.1 Remove the obsolete `specs/code-quality/testing/enforcement.md` member after confirming compact `enforcement.yaml` is authoritative.
- [x] 4.2 Run strict change validation, current-spec validation, coverage, and the review-panel conformance command; accept honest review-only/degraded quality coverage.
- [x] 4.3 Confirm no runner selection, live identity provisioning, mutation-boundary mechanism, or capability-specific assertion leaked into the Code-quality pair.
- [x] 4.4 Add `establish-live-verification-safety` as the separate prerequisite for follow-on changes that mutate deployed state.
