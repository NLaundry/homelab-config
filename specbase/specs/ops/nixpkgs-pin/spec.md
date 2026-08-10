---
id: ops.nixpkgs-pin
---

### Requirement: nixpkgs is pinned to a NixOS release with a committed lock
**ID:** `nixpkgs-release-pinned`
The flake input for nixpkgs SHALL pin a NixOS release channel matching the
deployed system's `system.stateVersion`. `flake.lock` SHALL be committed to the
repository so deploys are reproducible, and an update cadence SHALL be
documented.

#### Scenario: The flake input pins the NixOS release
**ID:** `flake-input-pins-release`
- **WHEN** `flake.nix` is inspected
- **THEN** the nixpkgs input URL references a NixOS release channel (e.g.
  `nixos-26.05`), not unstable

#### Scenario: The lock is committed and pins the resolved rev
**ID:** `lock-committed-pinned`
- **WHEN** `flake.lock` is inspected
- **THEN** it records a resolved nixpkgs revision for the pinned channel
- **AND** the file is tracked in the repository

#### Scenario: The flake evaluates against the pin
**ID:** `flake-evaluates-against-pin`
- **WHEN** `nix flake check` is run at the repo root
- **THEN** it evaluates the flake against `flake.lock` without error
