---
id: architecture.host-modules
---

### Requirement: Each host lives under hosts/<role>/ as a split module set
**ID:** `host-module-split`
Each NixOS host the repository manages SHALL live under `hosts/<role>/`. The
host directory SHALL contain `default.nix` (system, users, services) and
`hardware-configuration.nix` (hardware scan), and MAY contain role-specific
modules. `default.nix` SHALL import `hardware-configuration.nix` and every
role-specific module in the host directory, so the host is composed from its
sibling modules.

#### Scenario: default.nix imports its sibling modules
**ID:** `default-imports-siblings`
- **WHEN** `hosts/<role>/default.nix` is inspected
- **THEN** it imports `./hardware-configuration.nix`
- **AND** it imports every other `./<module>.nix` present in the same host
  directory

#### Scenario: The role-specific module owns its concern
**ID:** `role-module-owns-concern`
- **WHEN** a role has a concern isolated into a role-specific module (e.g.
  `zfs.nix`)
- **THEN** the concern's configuration lives in that module
- **AND** `default.nix` does not re-declare it
