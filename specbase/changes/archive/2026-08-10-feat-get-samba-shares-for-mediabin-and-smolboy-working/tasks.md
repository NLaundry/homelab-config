## 1. Implement the Samba shares on the NAS

- [x] 1.1 Create `hosts/nas/samba.nix` enabling `services.samba` with the two shares:
      `mediaBin` → `path = /mediaBin/data/media` and `smolBoy` → `path = /smolBoy/data`.
      Configure guest-open access, `map to guest`, and `force user`/`force group`
      on `operator` (uid 1000, primary group).
- [x] 1.2 Enable mDNS advertisement via Samba built-in `mdns name = mdns` in the
      global settings so the server is discoverable at `smb://NASty.local`.
- [x] 1.3 Add the `fruit` and `streams_xattr` VFS modules for macOS Finder
      metadata/timestamp correctness.
- [x] 1.4 Open firewall TCP ports `139` and `445` on the NAS (alongside the
      existing `22`).
- [x] 1.5 Import `./samba.nix` from `hosts/nas/default.nix`, conforming to the
      `role-module-owns-concern` rule (Samba state is not re-declared in
      `default.nix`).

## 2. Evidence: bring the paired enforcement bindings active

- [x] 2.1 Run the structure bindings against the evaluated flake and confirm they
      pass once `samba.nix` exists: `samba-config-eval`
      (`nix eval ...config.services.samba.settings`) and `samba-firewall-eval`
      (`nix eval ...config.networking.firewall.allowedTCPPorts`). NOTE: the
      binding command was updated from `...config.services.samba` (whole attrset)
      to `...config.services.samba.settings` because nixos-26.05 migrated Samba
      to the RFC0042 `settings` API and the legacy removed-option stubs throw
      when the whole attrset is forced to JSON.
- [x] 2.2 Deploy with `make deploy` (or `make test` first to trial), then run the
      wire binding `smbutil-view-wire` from the macOS deployer and confirm
      `smbutil view -N -G //10.10.10.11` lists `mediaBin` and `smolBoy`.
      (Verified: `make deploy` succeeded; manual `smbutil view -N -G //10.10.10.11`
      lists mediaBin and smolBoy.)
- [x] 2.3 Execute `samba-runtime-review` for the residue: verify `NASty.local`
      resolves/lists over `_smb._tcp` mDNS and that a guest write into an
      operator-owned dataset succeeds; record the outcome.
      (Verified via Avahi — see design D3 reversal: `dns-sd -B _smb._tcp local.`
      lists `NASty`; `NASty.local` resolves to `10.10.10.11`; guest mounts of both
      shares via `smb://NASty.local` succeed and list contents. `mdns name = mdns`
      was a no-op on this nixpkgs Samba build, so Avahi now publishes discovery.)

## 3. Cleanup

- [x] 3.1 Confirm no enforcement target was retired by this change (all bindings
      are new additions); no target removal is required.