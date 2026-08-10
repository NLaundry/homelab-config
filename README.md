# homelab-config

Configuration for the homelab. NixOS hosts are flake-managed; the rest of the
fleet (router, AP, Proxmox) stays on Ansible under `ansible/`.

## Layout

```
flake.nix                 # nixosConfigurations.nas  (nixpkgs nixos-26.05)
hosts/
  nas/                    # role name — NOT tied to the "NASty" hostname
    default.nix           # system, users (operator), ssh, services
    zfs.nix               # hostId, pool import, ZFS-compatible kernel
    hardware-configuration.nix
Makefile                  # remote deploy helpers
ansible/                  # non-Nix homelab hosts
docs/NAS/                 # runbooks (e.g. zpool-first-import.md)
openspec/                 # change proposals
```

## Deploying the NAS

The NAS (`NASty`, 10.10.10.11) is deployed remotely. Because the workstation is
macOS/aarch64 and can't build a Linux system locally, the build runs **on the
NAS** (`--build-host`); the workstation only evaluates the flake.

```bash
make deploy    # build on NAS + activate now + set as boot default (switch)
make test      # build on NAS + activate now, reverts on reboot (use for risky changes)
make boot      # build on NAS + set for next boot, no activation now
make dry       # show what would change
make build     # build on NAS only, no activation
make check     # evaluate the flake locally
```

Override the target if needed: `make deploy TARGET=root@10.10.10.11`.

Deploys currently authenticate as `root` over SSH (existing homelab key). SSH
hardening (key-only, disable password auth) is a deferred decision — see
`openspec/changes/archive/2026-08-06-flakify-nas/design.md`.

## nixpkgs updates

`flake.lock` pins nixpkgs. To move to a newer `nixos-26.05` snapshot:

```bash
nix flake update        # refresh flake.lock
make test               # trial the new closure before persisting
```

Commit `flake.lock` alongside config changes so deploys are reproducible.
