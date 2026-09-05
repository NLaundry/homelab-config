# Enforcement: each host lives under hosts/<role>/ as a split module set

Paired with `spec.md` (`architecture.host-modules`). The structural invariants
(`hosts/<role>/` layout; `default.nix` imports its sibling modules) are
conformance checks over the repo files. Architectural flavor: a parse/grep
fitness function protects the module-composition invariant across the repo.

```yaml
version: 1
spec: architecture.host-modules
bindings:
  - id: default-imports-siblings
    covers: [host-module-split, default-imports-siblings]
    mechanism: command
    strength: automated
    status: active
    targets:
      - hosts/nas/default.nix
    run:
      command: grep
      args:
        - -q
        - "./hardware-configuration.nix"
        - hosts/nas/default.nix
      cwd: .
    limitations: >-
      Proves default.nix imports hardware-configuration.nix; sibling role modules
      (e.g. zfs.nix) are covered by the import-zfs check below for the NAS, and
      by inspection for future hosts.

  - id: default-imports-role-module
    covers: [default-imports-siblings, role-module-owns-concern]
    mechanism: command
    strength: automated
    status: active
    targets:
      - hosts/nas/default.nix
    run:
      command: grep
      args:
        - -q
        - "./zfs.nix"
        - hosts/nas/default.nix
      cwd: .
    limitations: Proves default.nix imports zfs.nix for the NAS host; the general "imports every sibling" rule is asserted by the paired spec.
