## Why

The repository already ships a deployed NAS (`NASty`) whose durable truth lives
in a legacy flat OpenSpec spec (`openspec-old/specs/nixos-deploy/spec.md`,
`schema: spec-driven`) with no enforcement pairs. The repo has since moved to
the governed specbase model (`schema: spec-driven-governed`, 5 paired planes),
leaving the NAS's behavior, architecture, and ops with **zero governed
coverage** — only the two `agents` baseline pairs exist. The durable truth of an
already-shipped system needs to be re-homed into governed plane-qualified pairs
so it carries paired enforcement and the legacy layout can be retired.

## What Changes

- Establish **7 new governed spec pairs** re-homing the legacy `nixos-deploy`
  capability, split across behavior, architecture, and ops planes (one spec per
  plane-qualified locator; no plane mixing within a spec).
- **Behavior** (NAS-scoped, nested under `behavior/storage/`): the NAS boots with
  its ZFS pools imported; the `operator` user can administer over SSH with
  passwordless sudo; `vim` and `git` are enabled on the box.
- **Architecture** (top-level, applies to every Nix host): the flake exposes
  `nixosConfigurations.<role>` with a host-agnostic attribute name; each host
  lives under `hosts/<role>/` as a split module set (`default.nix` +
  `hardware-configuration.nix` + role-specific modules) with `default.nix`
  importing the rest.
- **Ops**: the deploy mechanism builds on the NAS and activates remotely via
  `nixos-rebuild --target-host`/`--build-host` over SSH as `operator` with
  passwordless sudo, exposed through a `Makefile` target surface; nixpkgs is
  pinned to `nixos-26.05` with a committed `flake.lock` and a documented update
  cadence.
- **Re-home** the shipped `flakify-nas` change verbatim from
  `openspec-old/changes/archive/` into `openspec/changes/archive/` so its
  deferred-decisions running list (D1–D9) stays discoverable at the canonical
  path. Its internal legacy `spec.md` delta is preserved as a historical
  snapshot (not rewritten into governed form).
- **Delete** `openspec-old/` once its content is re-homed or superseded.
- **Fix** the stale `README.md` reference to
  `openspec/changes/flakify-nas/design.md` (never existed at that path; the
  archive lives under a dated subdirectory).

No `code-quality` or `agents` pairs are in scope: the legacy content asserts no
code smells/qualities/rules, and the repo's agentic instruments are already
planted. The deployed system itself is unchanged — this is a spec-only
refactor.

## Planes

### Behavioral truth
<!-- User- or client-visible capabilities that must remain true now.
     Live at specs/behavior/<locator>/. -->
- `behavior.storage.nas-boot`: the NAS boots with its ZFS data pools imported,
  correct `hostId`, a ZFS-compatible kernel, and `forceImportRoot = false` with
  no eval warning (new)
- `behavior.storage.nas-users`: the `operator` admin user exists, can SSH in
  with an authorized key, and runs `sudo` without a password (new)
- `behavior.storage.nas-utility-packages`: `vim` and `git` are enabled on the NAS
  (new)

### Architectural truth
<!-- Package responsibilities, dependency invariants, cross-cutting structural
     policies that must remain true now. Live at specs/architecture/<locator>/. -->
- `architecture.flake-entry`: `flake.nix` exposes `nixosConfigurations.<role>`
  built from a nixpkgs input, with the attribute name host-agnostic (role name,
  not hostname) — applies to every Nix host the repo will manage (new)
- `architecture.host-modules`: each host lives under `hosts/<role>/` as a split
  module set — `default.nix` (system/users/services) imports
  `hardware-configuration.nix` and any role-specific modules (e.g. `zfs.nix`)
  — applies to every Nix host (new)

### Ops
<!-- What the project uses and how it runs — packages, dev env, IaC, deployment. -->
- `ops.deployment`: the remote-deploy mechanism (build on the NAS via
  `--build-host`, activate via `--target-host` over SSH as `operator` with
  passwordless sudo) and the `Makefile` target surface that exposes it
  (`deploy`/`boot`/`test`/`dry`/`build`/`check`) (new)
- `ops.nixpkgs-pin`: the flake input pins `nixpkgs` to `nixos-26.05`, `flake.lock`
  is committed, and an update cadence is documented (new)

## Spec pairs

<!-- Each governed spec is paired with an enforcement.md. For each plane target
     above, name the stable project-wide spec id and the mechanism you expect to
     protect it (test, lint, static-analysis, command, review, manual). -->
- `behavior.storage.nas-boot` -> paired enforcement via `command` (nix eval asserting config values) + `manual` (pools actually import on boot, requires the box)
- `behavior.storage.nas-users` -> paired enforcement via `command` (nix eval asserting operator config) + `manual` (operator can actually SSH + sudo, requires the box)
- `behavior.storage.nas-utility-packages` -> paired enforcement via `command` (nix eval asserting programs.vim/git)
- `architecture.flake-entry` -> paired enforcement via `command` (conformance: flake.nix exposes a `.#<role>` attribute; no hostname-derived attribute)
- `architecture.host-modules` -> paired enforcement via `command` (conformance: `hosts/<role>/default.nix` imports its sibling modules)
- `ops.deployment` -> paired enforcement via `command` (`make -n` expands targets to the expected nixos-rebuild flags) + `manual` (an end-to-end deploy succeeds, requires the box)
- `ops.nixpkgs-pin` -> paired enforcement via `command` (flake.lock pins the nixos-26.05 ref; `nix flake check` evaluates)

## Impact

- **New spec files** (all under `openspec/changes/migrate-to-governed-specs/specs/`
  as deltas, applied to `openspec/specs/` on archive):
  - `specs/behavior/storage/{nas-boot,nas-users,nas-utility-packages}/{spec,enforcement}.md`
  - `specs/architecture/{flake-entry,host-modules}/{spec,enforcement}.md`
  - `specs/ops/{deployment,nixpkgs-pin}/{spec,enforcement}.md`
- **Moved**: `openspec-old/changes/archive/2026-08-06-flakify-nas/` ->
  `openspec/changes/archive/2026-08-06-flakify-nas/` (verbatim; its legacy
  `.openspec.yaml` and `specs/nixos-deploy/spec.md` delta are kept as a
  historical snapshot of the pre-governed workflow).
- **Deleted**: `openspec-old/` (superseded by the governed pairs; the legacy
  `specs/nixos-deploy/spec.md` content is re-expressed as governed deltas).
- **Edited**: `README.md` line referencing `openspec/changes/flakify-nas/design.md`
  corrected to the archived path.
- **Unchanged**: the deployed NAS itself (`flake.nix`, `hosts/nas/*`, `Makefile`
  are not touched — this re-specs existing truth, it does not reconfigure the
  box), `ansible/`, `docs/`, and the existing `agents/` baseline pairs.
- **No `code-quality` or `agents` pairs** in scope (no smells/rules asserted;
  agentic instruments already planted and untouched).
