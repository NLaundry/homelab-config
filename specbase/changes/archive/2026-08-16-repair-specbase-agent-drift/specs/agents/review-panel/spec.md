---
id: agents.review-panel
---

## Purpose

This pair describes the repo-owned review panel that examines changed implementations through focused plane lenses and checks whether declared enforcement genuinely exercises its claims.

## MODIFIED Requirements

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
