# Tooling catalogue

This catalogue explains the direct tools selected for repository, deployment,
testing, and agent workflows. Executable authorities own exact versions and
hashes; this file records roles, scope, and replacement boundaries.

## Bootstrap and external prerequisites

| Role | Selected tool | Scope | Executable authority |
|---|---|---|---|
| Reproducible environment bootstrap | Nix with flakes | Operator workstations and build hosts | External Nix installation; repository inputs are locked by `flake.lock` |
| Agent-assisted repository work | Pi | Contributor workflow | External Pi installation with repository instruments under `.pi/` |
| Darwin LAN transport implementation | Apple OpenSSH at `/usr/bin/ssh` | `aarch64-darwin` connections to managed hosts | macOS platform, reached only through the adapter in `nix/tooling.nix` |

Nix must exist before `nix develop` or a flake app can run. Pi is optional for
ordinary repository commands and is not part of the shared package closure.
Apple OpenSSH is a bounded Darwin exception: macOS Local Network Privacy can
deny Nix-packaged OpenSSH access to LAN hosts while allowing the platform tool.
The shared package still owns the `ssh` command through a Nix-defined adapter;
Linux operators use the nixpkgs OpenSSH package directly.

## Shared operator tool set

`nix/tooling.nix` is the single package registry exposed as
`packages.<system>.repo-tools` and consumed by each default development shell.
`nix/operator-systems.txt` and `nix/direct-commands.txt` independently record
the supported-system and command contracts used to detect implementation drift;
they record no package versions. Registered Make recipes are dry-run against the
command inventory, with `nix` as their sole external bootstrap exception.

| Role | Selected tool | Scope | Executable authority |
|---|---|---|---|
| Repository operation facade | Make | Operator and automation workflows | `nix/tooling.nix`, `Makefile` |
| Source history and lockfile checks | Git | Repository maintenance | `nix/tooling.nix`, `flake.lock` |
| JSON processing | jq | Repository conformance sources | `nix/tooling.nix`, `flake.lock` |
| YAML processing | yq | Specbase instrument conformance | `nix/tooling.nix`, `flake.lock` |
| Shell test runner | Bats | Harness and deployed verification | `nix/tooling.nix`, task-specific apps in `flake.nix` |
| Shell static analysis | ShellCheck | Repository shell maintenance | `nix/tooling.nix`, `flake.lock` |
| Shell formatting | shfmt | Repository shell maintenance | `nix/tooling.nix`, `flake.lock` |
| Remote command transport | OpenSSH | Managed hosts and live verification | nixpkgs OpenSSH on Linux; Nix-defined adapter to platform `/usr/bin/ssh` on Darwin; `nix/tooling.nix` |
| Non-Nix fleet automation | Ansible | Router, access point, and Proxmox fleet | `nix/tooling.nix`, `ansible/` |
| Specification workflow and validation | Specbase | Planning and governed truth | `nix/specbase.nix`, `specbase/` |
| NixOS deployment adapter | `nixos-rebuild` | Remote NAS build and activation | Locked nixpkgs via `flake.lock`; local app in `flake.nix` |

## Derivation-carried execution tools

These tools belong to the operation or derivation that executes them; a builder
does not install the complete operator environment globally.

| Role | Selected tool | Scope | Executable authority |
|---|---|---|---|
| Declarative system configuration | NixOS modules | Managed NixOS hosts | `flake.nix`, `hosts/`, locked nixpkgs |
| Isolated system-test runner | NixOS test driver | `x86_64-linux` test derivations | `flake.nix`, `tests/harness/` |
| VM execution backend | QEMU with KVM acceleration | Remote Linux/KVM test store | `tests/harness/nixos-vm.nix`, locked nixpkgs; `TEST_STORE` selects placement |
| Live deployed-system verification | Bats app closure | Operator-side verification | `flake.nix`, `tests/verify/` |

## Not yet selected

| Role | Status |
|---|---|
| CI/CD orchestrator | No selection yet |
| Dedicated CI/test execution host | No selection yet |

## Catalogue boundary

Include a tool when repository-owned code invokes it directly or it fills an
operator, deployment, test, or managed-runtime role. Do not catalogue incidental
utilities or transitive closure members. A replacement updates this catalogue
only when the role, selection, scope, or executable authority changes.
