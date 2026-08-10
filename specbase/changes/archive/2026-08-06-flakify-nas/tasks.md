## 1. Flake + module scaffolding

- [x] 1.1 Create `flake.nix` with `nixpkgs` input `github:NixOS/nixpkgs/nixos-26.05` and `nixosConfigurations.nas = nixpkgs.lib.nixosSystem { modules = [ ./hosts/nas ]; }`
- [x] 1.2 `git mv hardware-configuration.nix hosts/nas/hardware-configuration.nix` (was untracked → plain `mv`; verbatim, no edits)
- [x] 1.3 Create `hosts/nas/default.nix` from current `configuration.nix` — boot loader, `networking.hostName = "NASty"`, NetworkManager, vim/git, openssh (permissive for now), firewall port 22, `system.stateVersion = "26.05"`; import `./hardware-configuration.nix` and `./zfs.nix`
- [x] 1.4 Create `hosts/nas/zfs.nix` — the `zfsCompatibleKernelPackages` let-block + `boot.kernelPackages`, `supportedFilesystems = [ "zfs" ]`, `hostId = "007f0200"`, `extraPools = [ "smolBoy" "mediaBin" ]`, and `forceImportRoot = false`
- [x] 1.5 Delete the now-migrated root `configuration.nix` (content lives in default.nix + zfs.nix)

## 2. Folded-in additions

- [x] 2.1 Add `users.users.operator` (isNormalUser, `wheel` + `networkmanager`, authorized ed25519 key) to `hosts/nas/default.nix`
- [x] 2.2 Add `security.sudo.wheelNeedsPassword = false;`
- [x] 2.3 Confirm `boot.zfs.forceImportRoot = false;` is present in `zfs.nix` (resolves the eval warning)

## 3. Deploy tooling

- [x] 3.1 Create `Makefile` with `deploy`/`boot`/`test`/`dry`/`build`/`check` targets using `--flake .#nas --target-host root@10.10.10.11 --build-host root@10.10.10.11` (escaped `\#` — a bare `#` starts a Make comment and dropped the attr)
- [x] 3.2 Ensure `HOST`/`TARGET`/`FLAKE` are overridable `?=` variables

## 4. Make it evaluable

- [x] 4.1 `git add -A` so the flake sees the new files (flakes ignore untracked files)
- [x] 4.2 Config evaluates cleanly — used `nix eval .#nixosConfigurations.nas.config.system.build.toplevel.drvPath` (stronger than `nix flake check`): resolves to `nixos-system-NASty-26.05...drv`, no `forceImportRoot` warning; pinned nixpkgs rev matches the box's current system
- [x] 4.3 `make build` — confirmed: build runs on the NAS (remote build works from macOS)

## 5. Deploy + verify on the box

- [x] 5.1 `make test` — non-persistent trial activation succeeded
- [x] 5.2 Verify: `ssh operator@10.10.10.11` succeeds with key (no password), `sudo whoami` → root with no prompt
- [x] 5.3 Verify: `zpool status` shows `smolBoy` + `mediaBin` ONLINE and imported (no `-f` needed on boot)
- [x] 5.4 `make deploy` — persisted as the boot generation
- [x] 5.5 Reboot check (optional): pools import automatically, box reachable

## 6. Housekeeping

- [x] 6.1 Update `README.md` with deploy usage (`make deploy`, host layout)
- [x] 6.2 Commit `flake.lock` and note update cadence — committed in `eb81b89`; cadence documented in README
