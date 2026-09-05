---
id: governance.operator-tooling
---

## Purpose

Operators receive a reproducible cross-platform tool environment and an authoritative catalogue that explains each selected tool without duplicating version truth owned by the lock.

## Requirements

### Requirement: Repository operations use one selected tool set
**ID:** `repository-tool-set`
The repository SHALL derive its selected operator tools from one Nix-defined package set across supported systems, with any native transport adapter declared as an explicit bounded exception.

#### Scenario: Supported system tool sets are evaluated
**ID:** `tool-sets-conform-across-systems`
- **WHEN** the operator tool set is evaluated for each supported system
- **THEN** the same declared tool roles resolve and every native exception is identified explicitly

### Requirement: Supported systems expose the operator development shell
**ID:** `operator-dev-shell`
Each supported Darwin and Linux system SHALL expose a default development shell backed by the selected operator tool set.

#### Scenario: Development shell is built
**ID:** `supported-shell-resolves-tools`
- **WHEN** the default shell is evaluated on a supported system
- **THEN** its commands resolve from the selected Nix tool derivations

### Requirement: Tool catalogue explains selected authority
**ID:** `tooling-catalogue`
The repository tool catalogue SHALL state each selected tool's role, scope, and authority without duplicating version values owned by the flake lock or package set.

#### Scenario: Catalogue entry is reviewed
**ID:** `catalogue-entry-is-non-duplicative`
- **WHEN** a selected tool's catalogue entry is reviewed
- **THEN** it explains why and where the tool is authoritative without restating its locked version
