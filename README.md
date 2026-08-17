# homelab-config

Configuration for the homelab. NixOS hosts are flake-managed; the rest of the
fleet (router, AP, Proxmox) stays on Ansible under `ansible/`.

## Layout

```
flake.nix                 # host configurations, test runners, and VM checks
hosts/
  nas/                    # role name — NOT tied to the "NASty" hostname
    default.nix           # system, users (operator), ssh, services
    zfs.nix               # hostId, pool import, ZFS-compatible kernel
    hardware-configuration.nix
Makefile                  # documented repository operation registry
tests/harness/            # operation and isolated-runner conformance
tests/tooling/            # reproducible operator-environment conformance
tests/agents/             # repository-owned agent instrument conformance
tests/specbase/           # selector-addressable governed evidence
tests/verify/             # deployed-homelab Bats checks
ansible/                  # non-Nix homelab hosts
docs/NAS/                 # runbooks (for example zpool-first-import.md)
specbase/                 # governed specifications and changes
```

## Reproducible operator environment

[Nix](https://nixos.org/) with flakes is the only command-line bootstrap
prerequisite. Pi remains an optional external agent-workflow tool. The shared
operator environment supports `aarch64-darwin` and `x86_64-linux`:

```bash
nix develop                         # interactive shell with direct repo tools
nix develop --command make lint     # same environment for automation
nix develop --command specbase --version
```

The shell consumes `packages.<system>.repo-tools`, whose single package registry
lives in `nix/tooling.nix`. Managed commands therefore do not depend on Homebrew
or global npm. On Darwin, its Nix-defined `ssh` adapter delegates to the platform
`/usr/bin/ssh`, avoiding the local-network denial observed with Nix-packaged
OpenSSH; Linux uses nixpkgs OpenSSH directly. Flake apps and checks still carry their own runtime closures;
they do not assume an operator has entered the development shell.

A remote test store needs Nix, SSH trust, a compatible system, and advertised
features such as `kvm` and `nixos-test`. It does not install the complete
operator tool set globally; each test derivation supplies QEMU and its other
execution tools.

## Repository operations

Run `make help` from `nix develop` (or through `nix develop --command`) for the
registered operation surface.

```bash
make lint      # strict current-spec validation, then flake evaluation
make test      # every safe non-live phase, including the remote VM suite
make verify    # selected Bats checks against the deployed homelab
make build     # build the NAS configuration without activation
make dry       # preview physical NAS activation
make try       # activate temporarily, then verify; activation reverts on reboot
make boot      # select the NAS generation for next boot without activation
make deploy    # activate persistently, then verify the deployed NAS
```

`lint`, `test`, and `verify` are intentionally separate. `lint` is the fast
validation/evaluation stage and starts no test or deployed-service probe. `test`
is the complete non-live gate: after lint it runs the registered harness,
tooling, agent-instrument, current-binding, and VM phases. Candidate systems run
only as disposable guests on an explicit private test-driver network. The
execution host supplies compute; `make test` does not activate a candidate generation
on that host and gives guests no physical-LAN interface or route.

`verify` runs selected checks against the current deployment without activating
a system. Successful `try` and `deploy` activations invoke the same default
suite automatically. If post-activation verification fails, the Make operation
fails but does not roll back: the temporary or persistent generation remains
active until the operator takes another lifecycle action. This foundation adds
only a non-mutating placeholder; it does not yet govern the repeatability of
future live checks or claim Samba, ZFS, user-access, or deployment-success
coverage.

Each phase remains directly runnable for focused diagnosis:

```bash
make test-harness
make test-tooling
make test-agents
make test-current-bindings
make test-vm
make verify
```

## Test execution store

The default `TEST_STORE` is the physical NAS's SSH-accessible Nix store:

```text
ssh-ng://operator@10.10.10.11?ssh-key=$HOME/.ssh/id_ed25519&system-features=kvm%20nixos-test
```

Only execution placement is configurable; the VM phase of `make test` always
selects `.#checks.x86_64-linux.vm-tests`. The tooling phase uses the same store
for its native x86_64-linux contract. Move those phases to another compatible
host by overriding the one URI:

```bash
make test TEST_STORE='ssh-ng://ci@builder.example?ssh-key=/path/to/key&system-features=kvm%20nixos-test'
```

The foreground Nix client targets this store with `--eval-store auto`; the Mac
continues to evaluate and orchestrate while the remote store coordinates Linux
builds and retains their outputs. This avoids Darwin's denial of daemon-owned
SSH connections used by `--builders` and lets the selected operator SSH
transport establish the connection. The remote account must be trusted by the
remote Nix daemon; the daemon's build users and sandbox must be able to access
`/dev/kvm`.

## Deploying the NAS

The NAS (`NASty`, `10.10.10.11`) is deployed remotely. Because the operator
workstation is macOS/aarch64, Linux builds run on the NAS through
`--build-host`; the workstation evaluates the flake and activates remotely.
Deployment defaults authenticate as `operator` with the configured Ed25519 key
and use passwordless sudo for activation. `try` and `deploy` run deployed
verification only after activation succeeds; a verification failure is reported
as a failed operation without claiming or attempting rollback. `boot`, `dry`,
and `build` do not run deployed verification because they do not activate a
candidate immediately.

Deployment inputs are independently overridable:

```bash
make deploy HOST=nas TARGET=operator@10.10.10.11 FLAKE='.#nas'
```

## nixpkgs updates

`flake.lock` pins nixpkgs. To move to a newer `nixos-26.05` snapshot:

```bash
nix flake update
make lint
make build
make try       # temporary physical activation before make deploy
```

Commit `flake.lock` alongside configuration changes so deployments remain
reproducible.
