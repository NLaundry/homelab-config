---
id: governance.network-iac
---

## Purpose

Repository network IaC has one reproducible authority for selected remote objects and excludes operational state from version control.

## Requirements

### Requirement: NetBird control-plane authority is singular
**ID:** `netbird-control-plane-authority`
The repository SHALL use one OpenTofu root as the routine change authority for its managed NetBird objects.

#### Scenario: A managed NetBird object changes
**ID:** `managed-netbird-change-uses-opentofu`
- **WHEN** an operator changes the managed North York Network or LAN resource
- **THEN** the change is declared and reconciled through the repository OpenTofu root

### Requirement: NetBird IaC is reproducible
**ID:** `netbird-iac-reproducible`
The supported operator environment SHALL initialize and validate the NetBird root with locked dependencies.

#### Scenario: A clean operator environment validates the root
**ID:** `clean-environment-validates-netbird`
- **WHEN** the NetBird root is initialized in a supported operator environment
- **THEN** its selected provider resolves from the committed declarations and validation succeeds

### Requirement: NetBird operational state is excluded from Git
**ID:** `netbird-state-excluded-from-git`
The repository SHALL exclude OpenTofu state and working data from tracked files.

#### Scenario: Repository contents are inspected
**ID:** `tracked-files-exclude-opentofu-state`
- **WHEN** tracked paths are checked
- **THEN** no NetBird OpenTofu state or working directory is present
