---
id: architecture.flake-entry
---

## ADDED Requirements

### Requirement: The flake exposes a host-agnostic NixOS configuration attribute
**ID:** `flake-exposes-role-attribute`
The repository SHALL contain a `flake.nix` that exposes
`nixosConfigurations.<role>` built from a nixpkgs input via
`nixpkgs.lib.nixosSystem`. The configuration attribute name SHALL be a
host-agnostic role name, independent of the machine's `networking.hostName`, so
that renaming the host touches no flake attribute or directory.

#### Scenario: The flake exposes a role-named configuration
**ID:** `role-attribute-exposed`
- **WHEN** the flake outputs are inspected
- **THEN** `nixosConfigurations.<role>` is addressable as `.#<role>`
- **AND** no flake attribute is named after a machine hostname

#### Scenario: The configuration evaluates
**ID:** `role-attribute-evaluates`
- **WHEN** `nix eval .#nixosConfigurations.<role>.config.system.build.toplevel.drvPath`
  is run at the repo root
- **THEN** it resolves to a derivation path without error
