# Enforcement: the flake exposes a host-agnostic NixOS configuration attribute

Paired with `spec.md` (`architecture.flake-entry`). The structural invariant
(flake exposes `.#<role>`; no hostname-derived attribute) is a conformance
check over `flake.nix`, plus a `nix eval` proving the attribute evaluates.
Architectural flavor: one fitness function protects the invariant across the
whole repo.

```yaml
version: 1
spec: architecture.flake-entry
bindings:
  - id: flake-exposes-role-attribute
    covers: [flake-exposes-role-attribute, role-attribute-exposed]
    mechanism: command
    strength: automated
    status: active
    targets:
      - flake.nix
    run:
      command: grep
      args: [-q, "nixosConfigurations\\.", flake.nix]
      cwd: .
    limitations: >-
      Proves a `nixosConfigurations.<attr>` is declared in flake.nix; does not
      by itself prove the attr is host-agnostic (the no-hostname-attr check below
      adds that).

  - id: no-hostname-derived-attribute
    covers: [flake-exposes-role-attribute, role-attribute-exposed]
    mechanism: command
    strength: automated
    status: active
    targets:
      - flake.nix
    run:
      command: bash
      args:
        - -c
        - "! grep -Eq 'nixosConfigurations\\.(NASty|nasty)' flake.nix"
      cwd: .
    limitations: Proves no `.#NASty`/`.#nasty` attribute exists; the general host-agnostic principle is asserted by the paired spec.

  - id: role-attribute-evaluates
    covers: [role-attribute-evaluates]
    mechanism: command
    strength: automated
    status: active
    targets:
      - flake.nix
    run:
      command: nix
      args:
        - eval
        - --raw
        - .#nixosConfigurations.nas.config.system.build.toplevel.drvPath
      cwd: .
    limitations: Proves the `nas` attribute evaluates to a derivation; does not prove the resulting system boots.
