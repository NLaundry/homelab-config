---
id: agents.review-panel
---

## Purpose

The review panel brings the repository's testing policy to changed test sources even when the surrounding capability change belongs to another truth plane.

## ADDED Requirements

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
