# homelab-config

NixOS configuration for the NAS. Ansible manages the other hosts.

## Start

Install [Nix](https://nixos.org/) with flakes enabled, then run:

```sh
nix develop
make help
```

The shell includes a colored prompt, modern terminal and Git tools, language
servers, and an isolated LazyVim setup available with `lazyvim`. See
[tooling.md](tooling.md) for the full list.

The shell supports macOS ARM and Linux x86-64. Full live SMB checks need macOS.

## Makefile commands

| Command | Action |
|---|---|
| `make check` | Evaluate Nix configuration without building or deploying |
| `make test-local` | Run isolated PKI, Ansible and OpenTofu regressions; dependencies may download |
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
this also works with `try` and `deploy`, but then skips the other probes.
Bats options are accepted by standalone `verify`, not activation preflight.
The test store needs Linux, Nix, SSH access, and KVM.

`make verify` runs every probe file under `tests/verify`; new `.bats` files
are registered automatically. The runner supplies non-secret probe context
(DNS/HTTPS targets) from `estate.yaml`. Secret-dependent connector probes
run under their SecretSpec scope when invoked inside `nix develop`
(secretspec, ansible and the operator age identity must be available),
and skip with a notice otherwise; the off-LAN routing probe only runs off
the LAN.

If macOS reports an SSH Unix socket path is too long, use a shorter temporary
path for the build: `TMPDIR=/tmp make build`. This changes no SSH trust setting
and does not activate the candidate.

## Files

- `hosts/nas/`: NAS configuration.
- `estate.yaml`: sites, hosts, optional VMs, and their services.
- `nix/dev.nix`: operator tools. See [tooling.md](tooling.md).
- `docs/`: [operations and recovery runbooks](docs/operations/README.md).
- `openspec/`: specs, changes, ideas, and stack order. See [planning](openspec/README.md).

Commit `flake.lock` with dependency updates to keep builds reproducible.
