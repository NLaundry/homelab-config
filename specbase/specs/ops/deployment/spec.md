---
id: ops.deployment
---

### Requirement: Deploys build on the host and activate remotely as operator
**ID:** `remote-deploy-mechanism`
The repository SHALL provide a deploy mechanism that builds the system on the
target host (not the workstation) and activates it remotely over SSH. The
build SHALL run on the host via `--build-host`, activation SHALL target the
host via `--target-host`, and the deploy SHALL authenticate as the non-root
`operator` user and escalate with passwordless sudo.

#### Scenario: The build runs on the host
**ID:** `build-on-host`
- **WHEN** a deploy is performed
- **THEN** `nixos-rebuild` is invoked with `--build-host` pointed at the NAS
- **AND** the build occurs on the NAS, not on the (macOS/aarch64) workstation

#### Scenario: Activation targets the host as operator
**ID:** `activate-as-operator`
- **WHEN** a deploy is performed
- **THEN** `nixos-rebuild` is invoked with `--target-host operator@10.10.10.11`
- **AND** escalation uses passwordless sudo (not root login)

#### Scenario: An end-to-end deploy succeeds
**ID:** `deploy-succeeds-runtime`
- **WHEN** a deploy is run against the NAS
- **THEN** the system builds on the NAS and activates without error
- **AND** the new generation is reachable over SSH afterwards

### Requirement: The Makefile exposes the deploy target surface
**ID:** `makefile-target-surface`
The repository SHALL provide a `Makefile` whose targets wrap the deploy
mechanism. It SHALL expose `deploy` (activate now + set as boot default),
`boot` (set for next boot, no activation), `test` (activate now, revert on
reboot), `dry` (show what would change), `build` (build only, no activation),
and `check` (evaluate the flake locally). `HOST`, `TARGET`, and `FLAKE` SHALL
be overridable.

#### Scenario: The Makefile targets expand to the expected command
**ID:** `makefile-targets-expand`
- **WHEN** `make -n deploy` (and the other targets) is run at the repo root
- **THEN** each target expands to a `nixos-rebuild` invocation with
  `--flake .#nas`, `--target-host`, and `--build-host`
- **AND** `deploy` uses `switch`, `boot` uses `boot`, `test` uses `test`, and
  `dry` uses `dry-activate`

#### Scenario: Deploy variables are overridable
**ID:** `makefile-vars-overridable`
- **WHEN** `make deploy TARGET=operator@10.10.10.11` is run
- **THEN** the overridable `TARGET`/`HOST`/`FLAKE` variables take effect in the
  expanded command
