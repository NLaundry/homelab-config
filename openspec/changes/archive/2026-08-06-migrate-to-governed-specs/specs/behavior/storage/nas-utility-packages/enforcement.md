# Enforcement: vim and git are enabled on the NAS

Paired with `spec.md` (`behavior.storage.nas-utility-packages`). A single
`nix eval` over the repo's flake proves both program options are enabled — one
command covers the whole family.

```yaml
version: 1
spec: behavior.storage.nas-utility-packages
bindings:
  - id: utility-packages-eval
    covers: [utility-packages-enabled, vim-git-enabled]
    mechanism: command
    strength: automated
    status: active
    targets:
      - hosts/nas/default.nix
    run:
      command: nix
      args:
        - eval
        - --json
        - .#nixosConfigurations.nas.config.programs
      cwd: .
    limitations: Confirms the program options are enabled in the evaluated flake, not that the binaries are usable on the booted box.
