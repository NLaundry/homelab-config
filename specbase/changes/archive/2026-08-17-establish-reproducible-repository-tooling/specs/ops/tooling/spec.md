---
id: ops.tooling
---

## Purpose

The repository gives operators and automation a reproducible set of direct tools while keeping tool roles understandable and preventing development dependencies from leaking into managed hosts or build infrastructure.

## ADDED Requirements

### Requirement: Direct repository tools come from one Nix package set
**ID:** `repository-tool-set`
The repository SHALL expose one shared Nix-defined package set for its direct repository commands on every supported operator system. Each direct implementation SHALL be selected through locked nixpkgs or an explicitly fixed source, except that a platform-native transport MAY be reached through a Nix-defined adapter when operating-system security prevents the packaged implementation from reaching managed hosts, and that exception SHALL be explicit in the tooling catalogue.

#### Scenario: A direct command is introduced
**ID:** `direct-command-declared`
- **WHEN** a repository-owned operation begins invoking a new direct command
- **THEN** the command's package is added to the shared tool set or recorded as an explicit bootstrap exception
- **AND** its version authority remains executable rather than duplicated in prose

#### Scenario: Platform security denies packaged transport to managed hosts
**ID:** `platform-transport-adapted`
- **WHEN** a supported operator system allows its native transport to reach managed hosts but denies that access to the packaged implementation
- **THEN** the shared package set supplies the command through a Nix-defined adapter to the platform-native transport
- **AND** other supported systems continue to use their locked or fixed implementation

### Requirement: Supported operators receive a default development shell
**ID:** `operator-dev-shell`
The supported operator systems SHALL be `aarch64-darwin` and `x86_64-linux`. The flake SHALL expose a default development shell for each supported operator system, and that shell SHALL supply the shared direct repository tool set.

#### Scenario: An operator enters the repository environment
**ID:** `operator-enters-dev-shell`
- **WHEN** an operator runs `nix develop` on a supported system
- **THEN** the direct repository commands are available without relying on Homebrew or globally installed npm packages

#### Scenario: Automation enters the repository environment
**ID:** `automation-enters-dev-shell`
- **WHEN** automation runs `nix develop --command <command>` on a supported system
- **THEN** the command receives the same direct tool environment as an interactive operator

### Requirement: The tooling catalogue records roles and authorities
**ID:** `tooling-catalogue`
The repository SHALL maintain a human-readable tooling catalogue that assigns each direct selected tool to a role, scope, and executable authority while leaving exact versions and transitive dependencies to their lock files or package definitions.

#### Scenario: A tool is selected or replaced
**ID:** `tool-selection-catalogued`
- **WHEN** a direct tool begins filling a repository role or replaces the tool currently filling it
- **THEN** the catalogue records the role, selection, scope, and executable authority
- **AND** any platform-native adapter records its bounded scope and external authority
- **AND** it does not duplicate version truth owned by that authority
