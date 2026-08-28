---
id: governance.specbase
---

## Purpose

The repository's Specbase and review-panel instruments conform to the homelab-native plane model and route changes through the policies that own their evidence and implementation concerns.

### Requirement: Repository practices spec-driven development via Specbase
**ID:** `practices-sdd`
The repository SHALL use the Specbase `spcb` workflow, and its runtime configuration SHALL declare the governed schema and exactly the Service, Estate, Configuration, Lifecycle, and Governance planes.

#### Scenario: Governed roster is inspected
**ID:** `governed-roster-declared`
- **WHEN** enforcement resolves `specbase/config.yaml`
- **THEN** the governed schema and exact five-plane roster are present

#### Scenario: Project validates under the resolved model
**ID:** `project-validates`
- **WHEN** strict Specbase validation runs against the current tree and active changes
- **THEN** it exits successfully without unknown roots or incomplete pairs

### Requirement: Review panel exposes the resolved plane lenses
**ID:** `panel-covers-planes`
The review panel SHALL expose scoped Service, Estate, Configuration, Lifecycle, and Governance lenses plus the cross-cutting Enforcement lens, with each lens declaring the question and spec-tree scope it owns.

#### Scenario: Lens roster is compared
**ID:** `lens-roster-conforms`
- **WHEN** the generated review-panel instrument is compared with the resolved plane roster
- **THEN** a missing, extra, duplicated, or differently scoped lens fails conformance

### Requirement: Test changes select enforcement-quality review
**ID:** `panel-routes-test-quality`
The review panel SHALL select `governance.enforcement-quality` whenever a change adds, modifies, renames, or deletes a path beneath `tests/**`, without changing the panel's advisory and non-gating role.

#### Scenario: Test path changes
**ID:** `test-change-routes-enforcement-quality`
- **WHEN** a change touches any path beneath `tests/**`
- **THEN** enforcement-quality review is selected in addition to the ordinary affected-plane lenses

#### Scenario: No test path changes
**ID:** `non-test-change-keeps-normal-routing`
- **WHEN** a change touches no path beneath `tests/**`
- **THEN** the panel selects lenses only from ordinary affected-pair routing
