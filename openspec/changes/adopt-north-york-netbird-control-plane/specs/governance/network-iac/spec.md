---
id: governance.network-iac
---

## Purpose

Repository network IaC has one reproducible authority for each managed remote control plane and excludes operational state from version control.

## ADDED Requirements

### Requirement: NetBird control-plane authority is singular
**ID:** `netbird-control-plane-authority`
The repository SHALL use one OpenTofu root as the routine change authority for every managed NetBird control-plane object.

#### Scenario: Managed NetBird object changes
**ID:** `managed-netbird-change-uses-opentofu`
- **WHEN** an operator changes a managed NetBird Network, resource, group, router assignment, policy, or DNS object
- **THEN** the change is declared and reconciled through the repository OpenTofu root

### Requirement: NetBird IaC is reproducible
**ID:** `netbird-iac-reproducible`
The supported operator environment SHALL initialize and validate the NetBird root with locked dependencies and no undeclared local tooling.

#### Scenario: Clean operator environment validates the root
**ID:** `clean-environment-validates-netbird`
- **WHEN** the NetBird root is initialized in a clean supported operator environment
- **THEN** its selected dependencies and modules resolve to the committed declarations and validation succeeds

### Requirement: NetBird operational state is excluded from Git
**ID:** `netbird-state-excluded-from-git`
The repository SHALL exclude OpenTofu state, state backups, saved plans, and working data from tracked files.

#### Scenario: Repository contents are inspected
**ID:** `tracked-files-exclude-opentofu-state`
- **WHEN** tracked paths are checked
- **THEN** no NetBird OpenTofu operational state or saved plan is present
