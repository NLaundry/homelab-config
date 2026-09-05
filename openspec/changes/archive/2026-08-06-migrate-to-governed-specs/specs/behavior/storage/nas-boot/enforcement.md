# Enforcement: NAS boots with its ZFS data pools imported and forceImportRoot clean

Paired with `spec.md` (`behavior.storage.nas-boot`). The declarative config
intent (pools declared, hostId, ZFS filesystem, kernel selection, forceImportRoot
value) is proven from the workstation by `nix eval` over the repo's flake — one
eval family covers the whole "is this in the config" territory. The runtime
outcome (pools actually import on boot) genuinely requires the box, so it is an
honest `manual` binding.

```yaml
version: 1
spec: behavior.storage.nas-boot
bindings:
  - id: config-intent
    covers: [pools-import-on-boot, pools-declared, zfs-kernel-selected, force-import-root-clean, force-import-root-false-clean]
    mechanism: command
    strength: automated
    status: active
    targets:
      - flake.nix
      - hosts/nas/zfs.nix
    run:
      command: nix
      args:
        - eval
        - --raw
        - .#nixosConfigurations.nas.config.boot.zfs.extraPools
      cwd: .
    limitations: >-
      Proves the config intent is present in the evaluated flake, not that the
      pools import cleanly on a real boot. Eval does not exercise the kernel
      module's brokenness flag beyond what nixpkgs reports at eval time.

  - id: eval-no-force-import-root-warning
    covers: [force-import-root-clean, force-import-root-false-clean]
    mechanism: command
    strength: automated
    status: active
    targets:
      - hosts/nas/zfs.nix
    run:
      command: nix
      args: [eval, .#nixosConfigurations.nas.config.boot.zfs.forceImportRoot]
      cwd: .
    limitations: Confirms forceImportRoot is false; a full eval-warning capture belongs to `nix flake check` (ops.nixpkgs-pin).

  - id: pools-import-on-boot-runtime
    covers: [pools-import-on-boot-runtime]
    mechanism: manual
    strength: manual
    status: active
    targets:
      - hosts/nas/zfs.nix
    procedure: >-
      On the booted NAS, run `zpool status` and confirm `smolBoy` and `mediaBin`
      are ONLINE and imported without `-f`. Requires the box; cannot be exercised
      from the macOS workstation.
    rationale: >-
      Pool import on boot is a runtime outcome of the booted system; no
      workstation-side check meaningfully proves it.
    limitations: Confirms the runtime state at the time it is run, not on every boot.
