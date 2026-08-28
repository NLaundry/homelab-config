---
id: governance.nix-repository
---

## Purpose

The Nix repository exposes reproducible host definitions through stable role-oriented interfaces and keeps host-module ownership explicit enough for operators and tooling to reason about changes.

## MODIFIED Requirements

### Requirement: Flake exposes role-oriented host outputs
**ID:** `flake-exposes-role-attribute`
The flake SHALL expose each managed NixOS host through a stable role-oriented `nixosConfigurations` attribute that evaluates independently of the host's runtime hostname.

#### Scenario: Managed role is evaluated
**ID:** `role-output-evaluates`
- **WHEN** a managed role output is evaluated
- **THEN** it resolves a NixOS system closure without deriving its attribute name from the runtime hostname

### Requirement: Host modules have explicit ownership
**ID:** `host-module-split`
Each managed host SHALL have one role directory whose entry module composes its hardware and concern-specific sibling modules without duplicating their owned configuration.

#### Scenario: Host module set is inspected
**ID:** `host-module-ownership-conforms`
- **WHEN** a managed host role directory is inspected
- **THEN** its entry module composes the declared hardware and concern modules and those modules own their selected concerns

### Requirement: Nix inputs are reproducibly pinned
**ID:** `nixpkgs-release-pinned`
The repository SHALL resolve its selected Nix package set through the committed flake lock, and every managed host closure SHALL evaluate against that resolved input.

#### Scenario: Locked host closure is evaluated
**ID:** `locked-input-builds-host`
- **WHEN** a managed host closure is evaluated or built
- **THEN** it uses the committed resolved package-set input without an uncommitted dependency resolution
