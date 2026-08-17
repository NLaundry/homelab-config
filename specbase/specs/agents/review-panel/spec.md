---
id: agents.review-panel
---

## Purpose
This pair describes the repo-owned review panel that examines changed implementations through focused plane lenses and checks whether declared enforcement genuinely exercises its claims.

## ADDED Requirements

### Requirement: The review panel exposes the resolved review lenses
**ID:** `panel-covers-planes`
The review panel SHALL provide the non-cross-cutting `behavioural`, `architectural`, `ops`, and `code-quality` lenses plus the cross-cutting `enforcement` lens. Each lens SHALL declare the question and spec-tree scope it owns, and the resolved instrument SHALL conform to that declared set.

#### Scenario: A lens exists for each reviewed implementation plane
**ID:** `lens-per-plane`
- **WHEN** the repo-owned review-panel skill is inspected
- **THEN** it declares one scoped lens for behavior, architecture, ops, and code quality
- **AND** it declares the cross-cutting enforcement lens

#### Scenario: Resolved lenses conform to the spec
**ID:** `lenses-conform`
- **WHEN** the resolved coverage lens set is compared with the review-panel skill
- **THEN** enforcement reports a missing, extra, or differently scoped lens

### Requirement: Test-source changes select the testing-quality policy
**ID:** `panel-routes-test-quality`
The review-panel instrument SHALL select the Code-quality lens with `code-quality.testing` as policy whenever a change adds, modifies, renames, or deletes a path beneath the repository test tree, without changing the panel's advisory and non-gating role.

#### Scenario: A behavioral change adds a test
**ID:** `behavior-change-routes-test-quality`
- **WHEN** a change modifies `tests/**` and a Behavioral pair without touching a Code-quality pair
- **THEN** the review panel selects the Code-quality testing policy in addition to the lenses selected by the affected pairs

#### Scenario: A change does not modify tests
**ID:** `non-test-change-keeps-normal-routing`
- **WHEN** a change adds, modifies, renames, or deletes no path beneath `tests/**`
- **THEN** the review panel derives its selected lenses from the ordinary affected-pair router
