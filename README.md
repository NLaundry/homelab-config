# homelab-config

NixOS configuration for the NAS. Ansible manages the other hosts.

## Start

Install [Nix](https://nixos.org/) with flakes enabled, then run:

```sh
nix develop
make help
```

The shell supports macOS ARM and Linux x86-64. Full live SMB checks need macOS.

## Makefile commands

| Command | Action |
|---|---|
| `make check` | Evaluate Nix configuration without building or deploying |
| `make test-vm` | Evaluate, then test Samba in disposable VMs on `TEST_STORE` |
| `make verify` | Check live NAS health and guest SMB file access |
| `make build` | Build the NAS configuration without activation |
| `make preview` | Preview activation without applying it |
| `make try` | Activate temporarily, then verify |
| `make boot` | Select a configuration for the next boot |
| `make deploy` | Activate persistently, then verify |

`try` changes the running NAS but leaves the previous boot default in place.
Rebooting returns to that default. `try` and `deploy` check local prerequisites
before activation and verify afterward. **Failed verification does not roll back
the activation.**

The VM checks Samba, not physical storage. Live checks create and remove test
files on the shares. They check current health, not every deployment outcome.

Defaults target `operator@10.10.10.11`. Override `HOST`, `TARGET`, `KEY`, `FLAKE`,
or `TEST_STORE` on the command line. Use `VERIFY_ARGS` to select live test files.
For SSH-only verification on Linux, use `VERIFY_ARGS=tests/verify/deployment.bats`;
this also works with `try` and `deploy`, but does not check SMB.
Bats options are accepted by standalone `verify`, not activation preflight.
The test store needs Linux, Nix, SSH access, and KVM.

## Files

- `hosts/nas/`: NAS configuration.
- `estate.yaml`: sites, hosts, optional VMs, and their services.
- `nix/dev.nix`: operator tools. See [tooling.md](tooling.md).
- `docs/`: [operations and recovery runbooks](docs/operations/README.md).
- `openspec/`: specs, changes, ideas, and stack order. See [planning](openspec/README.md).

Commit `flake.lock` with dependency updates to keep builds reproducible.
