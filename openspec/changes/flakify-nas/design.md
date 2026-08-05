## Context

The NAS runs NixOS 26.05 with an imperative `/etc/nixos/configuration.nix`. The current config already: enables ZFS, sets `hostId = "007f0200"`, imports pools `smolBoy` + `mediaBin` via `extraPools`, auto-selects the latest ZFS-compatible kernel via a `let` filter, and enables `vim`/`git`/`openssh`. Root is on nvme (ext4); the four spinning disks hold the two ZFS data pools (creation already done, import only). The workstation driving deploys is **macOS/aarch64**, which cannot build an `x86_64-linux` system locally.

This change moves that config into the repo as a flake, splits it into modules, and adds a Makefile for remote deploy. It does **not** create pools, manage secrets, or harden SSH — those are deferred.

## Goals / Non-Goals

**Goals:**
- Flake-based, repo-driven definition of the NAS addressable as `.#nas` (host-agnostic name).
- Modular split: `default.nix` + `zfs.nix` + `hardware-configuration.nix`.
- One-command remote deploy that builds on the NAS.
- Fold in the `operator` user and `forceImportRoot = false`.
- Preserve current behavior otherwise.

**Non-Goals:**
- Pool creation / disko (pools exist, import only).
- Secrets management / sops (D2).
- SSH hardening — root login & password auth stay as-is for now (D8).
- Nix-ifying other homelab hosts (D4). Structure allows it later; not done here.
- deploy-rs / colmena / rollback tooling (D1).

## Decisions

### D-A: Flake tracks `nixos-26.05` (not unstable)
The box's `system.stateVersion` is `26.05` and its store path shows the `nixos-26.05` channel. Pinning the input to `github:NixOS/nixpkgs/nixos-26.05` keeps eval consistent with what's deployed. Alternative (unstable) rejected: needless churn for a NAS.

### D-B: `--build-host` = the NAS
`nixos-rebuild --target-host` evaluates locally but builds locally by default. On macOS/aarch64 that build fails (no Linux builder). Setting `--build-host root@10.10.10.11` delegates the build to the NAS; the workstation only evaluates the flake and orchestrates. Alternative (a local linux-builder VM) rejected as heavier than needed.

### D-C: Module split (default.nix + zfs.nix)
`zfs.nix` owns everything storage/kernel: `supportedFilesystems`, `hostId`, `extraPools`, `forceImportRoot`, and the `zfsCompatibleKernelPackages` `let`-block driving `boot.kernelPackages`. `default.nix` owns boot loader, networking, users, SSH, packages, and imports the other two. Keeps the ZFS-specific complexity isolated and makes the host readable.

### D-D: Host-agnostic naming
Directory `hosts/nas/` and attribute `.#nas` are role names. `networking.hostName = "NASty"` stays inside `default.nix`. Renaming the box later touches one line and doesn't move files.

### D-E: Deploy as root
The existing `~/.ssh/ansible_homelab` key reaches the box as root, and `services.openssh` currently allows root login. So `--target-host root@…` works today with zero new setup. When D8 (hardening) lands, deploy switches to `operator` + `--use-remote-sudo`.

## File blueprint

### `flake.nix`
```nix
{
  description = "Homelab NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.nas = nixpkgs.lib.nixosSystem {
      # system is provided by nixpkgs.hostPlatform in hardware-configuration.nix
      modules = [ ./hosts/nas ];
    };
  };
}
```

### `hosts/nas/default.nix`
```nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./zfs.nix
  ];

  # Boot loader (systemd-boot / EFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "NASty";
  networking.networkmanager.enable = true;

  programs.vim.enable = true;
  programs.git.enable = true;

  # Admin user — key-based SSH, passwordless sudo (folded in per decision).
  users.users.operator = {
    isNormalUser = true;
    description = "operator";
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOL27pePjsRIuaHTf1FLGp7Q+WFmpTE0nv4tPpsATEXP me@nathanlaundry.com"
    ];
  };
  # operator has no password; allow wheel to sudo without one.
  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      # NOTE: kept permissive for now; tighten under deferred D8.
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 ];

  system.stateVersion = "26.05";
}
```

### `hosts/nas/zfs.nix`
```nix
{ config, lib, pkgs, ... }:

let
  # Pick the newest kernel that still has a non-broken ZFS module.
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in
{
  # Note: this may jump around as kernels are added/removed upstream.
  boot.kernelPackages = latestKernelPackage;

  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "007f0200";

  # Data pools already exist on disk — import only, never create.
  boot.zfs.extraPools = [ "smolBoy" "mediaBin" ];

  # Safer default (becomes the default in 26.11); silences the eval warning.
  boot.zfs.forceImportRoot = false;
}
```

### `hosts/nas/hardware-configuration.nix`
Moved verbatim from the repo root (real disk UUIDs, `kvm-intel`, `nixpkgs.hostPlatform = "x86_64-linux"`). No edits.

### `Makefile`
```makefile
# Homelab NixOS deploy.
# Builds ON the NAS (workstation is macOS/aarch64 and can't build Linux locally).

HOST     ?= nas
TARGET   ?= root@10.10.10.11
FLAKE    ?= .#$(HOST)

REBUILD  = nixos-rebuild --flake $(FLAKE) \
             --target-host $(TARGET) \
             --build-host $(TARGET)

.PHONY: deploy boot test dry build check fmt

deploy:   ## Build on NAS + activate now (switch) + set for boot
	$(REBUILD) switch

boot:     ## Build on NAS + set for next boot, no activation now
	$(REBUILD) boot

test:     ## Build on NAS + activate now, do NOT persist to bootloader
	$(REBUILD) test

dry:      ## Show what would change without applying
	$(REBUILD) dry-activate

build:    ## Build on NAS only, no activation (sanity check)
	nixos-rebuild --flake $(FLAKE) --build-host $(TARGET) build

check:    ## Evaluate the flake locally
	nix flake check
```

> If `nixos-rebuild` isn't on the macOS PATH, targets can be run as
> `nix run nixpkgs#nixos-rebuild -- …`; the apply step can add a `NRB ?=`
> variable for that if needed.

## Risks / Trade-offs

- **Flakes ignore untracked files** → the new files won't be seen by `nix` until `git add`-ed. Mitigation: apply step runs `git add` before the first deploy; verification calls it out.
- **Local build on macOS fails** → mitigated by `--build-host` (decision D-B). Without it, `make deploy` would try to build `x86_64-linux` on aarch64-darwin and fail.
- **Deploying a bad network/SSH config could lock you out** → no automatic rollback yet (D1). Mitigation: use `make test` first (reverts on reboot) for risky changes; keep a serial/console fallback.
- **`operator` with passwordless sudo** → convenience over hardening; conscious homelab choice. Revisit with D8.
- **hostId `007f0200` is the generic localhost-derived default** → fine for a single host; note if pools are ever shared between machines.
- **Kernel auto-selection may jump versions** → inherited from current config; acceptable, keeps ZFS buildable.

## Migration Plan

1. Create `flake.nix`, `hosts/nas/{default.nix,zfs.nix}`; `git mv` the two root `.nix` files into `hosts/nas/` (hardware) / fold into `default.nix`+`zfs.nix` (configuration).
2. Remove the now-empty root `configuration.nix` / `hardware-configuration.nix`.
3. `git add -A` so the flake sees the files; `nix flake check` to eval.
4. `make test` for a non-persistent trial, verify SSH as `operator` + pools mounted, then `make deploy`.
5. Rollback: previous generation stays in the bootloader; `make test` auto-reverts on reboot if activation misbehaves.

## Deferred decisions (running list)

| # | Decision | Status |
|---|---|---|
| D1 | Remote deploy tooling (deploy-rs / colmena / rollback) | deferred — start with plain `nixos-rebuild` |
| D2 | Secrets management (sops-nix favored) | deferred |
| D3 | ZFS snapshots / scrub / autoSnapshot schedules | deferred |
| D4 | Nix-ify other hosts (proxbox, opnsense) | deferred — structure supports it |
| D5 | Dataset mountpoint strategy (native vs legacy) | deferred — pools use native mounts so far |
| D6 | Kernel must be ZFS-compatible | **RESOLVED** — auto-select `let`-block in `zfs.nix` |
| D7 | Encrypted-dataset key management | **RESOLVED (for now)** — the only encrypted dataset (lost key) was destroyed |
| D8 | SSH hardening (key-only root, disable password auth) | deferred — unblocked once `operator` verified |
| D9 | Create non-root `operator` admin user | **RESOLVED** — folded into this change |

## Open Questions

- Should `make deploy` eventually target `operator` + `--use-remote-sudo` instead of root? (Ties to D8.)
- Do we want a `flake.lock` commit policy / `nix flake update` cadence documented in a runbook?
