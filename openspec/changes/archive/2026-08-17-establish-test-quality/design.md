## Context

`establish-testing-operations` supplies NixOS VM and Bats runners, but runners do not determine whether their evidence is meaningful. Existing enforcement includes an SMB command whose success does not assert the expected shares, while the harness also contains stronger controlled-regression fixtures that prove a checker detects a specific defect.

The original version of this change compressed several concerns into three compound requirements and used obsolete Markdown enforcement fields. It also promised review of future tests even though the review-panel router selects plane lenses only from touched spec pairs. A capability change that modifies `tests/**` without touching `code-quality.testing` would therefore never receive the promised Code-quality review.

## Goals / Non-Goals

**Goals:**

- Define atomic, runner-neutral qualities for trustworthy repository tests and helpers.
- Require tests to exercise responsible production paths with defect-sensitive independent assertions.
- Make waiting, mutable state, cleanup, residue, and failure diagnostics reviewable without prescribing a test framework.
- Route changed test sources to the testing policy while preserving the panel's advisory, non-gating role.
- Use compact requirement-level enforcement indexes accepted by the current CLI.

**Non-Goals:**

- Select runners, Make targets, coverage quotas, naming conventions, assertion libraries, or universal property/mutation testing.
- Create an automated semantic meta-test or make review findings gate validation or archive.
- Provision live-verification identities, credentials, shares, or mutable-state boundaries.
- Rewrite capability-specific tests in this change.

## Decisions

### Keep source quality separate from evidence adequacy

The Code-quality pair states what good test source looks like. The cross-cutting enforcement lens remains responsible for judging whether a binding's source genuinely proves its covered requirement. Production-path and oracle questions therefore use the enforcement lens, while synchronization, isolation, cleanup, and diagnostics use the Code-quality lens.

### Prefer atomic rules over a three-item slogan

The permanent pair separates production-path fidelity from oracle sensitivity, run scoping from order independence, cleanup execution from original-failure preservation, residual failure from resource identification, and outcome naming from diagnostic-context preservation. These claims fail for different reasons and can evolve independently. Optional techniques such as table-driven style, property testing, snapshots, and mutation scores remain guidance until a recurring defect earns a requirement.

### Route the existing repository test tree

The review-panel instrument will inspect changed paths before selecting lenses. An added, modified, renamed, or deleted path beneath `tests/**` selects the `code-quality` lens and supplies `code-quality.testing` as its policy even when no Code-quality delta is present. The ordinary touched-pair router continues to select all other lenses, and the enforcement lens continues to inspect affected bindings.

This is path-aware routing for the repository's established central test tree, not an unconditional global style review. If test sources later move outside `tests/**`, the instrument contract must change deliberately.

### Keep review advisory

Review findings are reported with review strength and never block archive, readiness, or strict validation. A degraded coverage state is an honest description of semantic rules protected only by judgment. Deterministic conformance checks protect only the review instrument's routing behavior; they do not claim that reviewers will reach a particular verdict.

### Treat the home network as an invocation assumption

Live checks are invoked from the home deployment environment, which is expected to reach the NAS and possess required credentials. Once invoked, an unreachable endpoint, missing credential, or assertion failure is non-zero; this change adds no eligibility detection or green skip machinery.

## Enforcement design

### Semantic evidence review

The enforcement lens reads each changed requirement, binding, and test source together. It traces the covered requirement to the responsible production path and an assertion whose expected result is independent of the value under test. A finding identifies the uncovered requirement or self-fulfilling oracle. Review does not mechanically prove all future defect classes and remains advisory.

### Test hygiene review

The Code-quality lens reads changed files beneath `tests/**`, including invoked helpers, against `code-quality.testing`. It examines waits, run namespaces, dependence on prior residue or order, cleanup behavior across supported failures, residual-state reporting, and diagnostic context. Review cannot prove cleanup after host loss or process termination outside supported teardown boundaries.

### Review routing conformance

`tests/agents/specbase-instruments.sh#test-quality-routing` uses controlled changed-path fixtures to inspect the review-panel instrument. A fixture changing `tests/**` must select the Code-quality testing policy without requiring a Code-quality spec delta; a non-test fixture must not gain that route. The source fails non-zero on routing drift. It proves instrument selection, not the quality of any review verdict.

## Risks / Trade-offs

- **Advisory findings may remain unresolved** -> State that limitation explicitly and rely on human disposition rather than misrepresenting review as a gate.
- **Path routing misses relocated tests** -> Bind routing to the current central test tree and revise the Agents pair if the repository layout changes.
- **Broad language becomes subjective** -> Keep one falsifiable claim per requirement and use representative counterexamples in review fixtures.
- **Review duplicates the enforcement lens** -> Split ownership: enforcement judges proof adequacy; Code quality judges source hygiene.
- **The generated workflow prose can drift from the CLI schema** -> Follow CLI instructions here; refresh generic generated skills in separate Agents work.

## Migration Plan

1. Land the remaining real KVM execution task in `establish-testing-operations`.
2. Replace the obsolete testing enforcement Markdown with compact YAML and add the `agents.review-panel` delta.
3. Extend the review-panel router and its deterministic conformance source for `tests/**`.
4. Exercise both advisory lenses over one hollow binding and one strong controlled-regression test.
5. Run strict change validation and coverage, accepting review-only/degraded quality coverage.
6. Rebase the Samba, access, boot, and deployment verification changes on this policy and the separate live-verification safety change.
