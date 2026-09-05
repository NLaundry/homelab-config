---
id: governance.deployment-control
---

## Purpose

The repository's deployment control interface resolves explicit targets and inputs into an inspectable remote deployment plan without confusing orchestration evidence with a successful host transition.

## MODIFIED Requirements

### Requirement: Deployment control resolves the selected remote plan
**ID:** `remote-deploy-mechanism`
The deployment control interface SHALL resolve the selected flake target, remote build host, activation host, SSH identity, and privilege boundary before invoking the deployment transition.

#### Scenario: Deployment plan is inspected
**ID:** `remote-plan-resolves`
- **WHEN** an operator selects a remote deployment operation
- **THEN** the resolved plan identifies its flake target, build target, activation target, remote identity, and privilege boundary

### Requirement: Deployment inputs are overridable without repository edits
**ID:** `deployment-inputs-overridable`
The deployment control interface SHALL allow its host, target, and flake inputs to be overridden explicitly without editing repository files.

#### Scenario: Alternate deployment inputs are selected
**ID:** `alternate-inputs-resolve`
- **WHEN** an operator supplies alternate host, target, or flake inputs
- **THEN** the resolved deployment plan uses those values and leaves repository sources unchanged
