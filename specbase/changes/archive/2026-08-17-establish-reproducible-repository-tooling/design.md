## Context

`tooling.md` already records direct tool roles and deliberately delegates exact versions to executable authorities, but the repository currently exposes no development shell or shared package set. Commands therefore inherit Homebrew/global npm state on the aarch64-darwin operator workstation. The initial Linux/KVM test builder has a different responsibility: it should provide Nix and virtualization capacity while individual derivations carry their own runtime dependencies.

The testing-operations change is about to add Bats entry points and VM checks. Establishing the operator tool environment first prevents those runners from inventing another package list and gives future CI an executable repository bootstrap contract.

## Goals / Non-Goals

**Goals:**

- Define direct repository tools once in Nix and pin them through `flake.lock` or explicit source hashes.
- Expose a default development shell and reusable package set for `aarch64-darwin` and `x86_64-linux` without adding a flake utility dependency.
- Package tools invoked directly by repository operations, including Specbase and Bats, rather than relying on ambient Homebrew/npm installations.
- Preserve `tooling.md` as the human role/rationale catalogue and point entries to executable authorities.
- Give testing operations and future CI a shared package source without globally installing the whole developer environment on builders.

**Non-Goals:**

- Install development tools into the deployed NAS generation or a future builder host.
- Make Nix self-hosting; Nix remains the bootstrap prerequisite.
- Package Pi in this first change; Pi remains an external agent-workflow prerequisite recorded in the catalogue.
- Define VM isolation, KVM builder capabilities, harness semantics, or substantive homelab tests.
- List transitive dependencies or every executable present in a Nix closure.

## Decisions

### Use one Nix tool registry

`nix/tooling.nix` will return the supported operator systems and the direct package list for a supplied nixpkgs package set. Independent manifests in `nix/operator-systems.txt` and `nix/direct-commands.txt` prevent the implementation from silently shrinking either contract. `flake.nix` will use a small local system-mapping helper to expose `packages.<system>.repo-tools` and `devShells.<system>.default` without introducing flake-utils.

The initial direct command set covers repository operations and maintenance: Make, Git, jq, yq, Bats, ShellCheck, shfmt, OpenSSH, Ansible, and Specbase. Nixpkgs supplies ordinary packages. Specbase is packaged from a pinned npm source/version with fixed hashes so `make lint` does not depend on a global npm install. The implementation will verify the pinned nixpkgs deployment adapter works from aarch64-darwin before replacing the current registry-based `nix run nixpkgs#nixos-rebuild` path.

On aarch64-darwin, macOS Local Network Privacy permits Apple OpenSSH to reach LAN hosts while the Nix-packaged OpenSSH executable can receive `EHOSTUNREACH`. The Darwin package selection therefore exposes a Nix-store `ssh` adapter that delegates only to `/usr/bin/ssh`; x86_64-linux continues to select nixpkgs OpenSSH. This is a bounded platform transport exception rather than permission to resolve arbitrary ambient tools.

### Separate bootstrap, operator, app, and builder dependencies

Nix is required before `nix develop` can work, and Pi remains external in this change. The default dev shell supplies interactive operator/contributor tools. Under the Nix packaging selected by this change, each repository app or check includes its runtime inputs and may reuse the shared definitions without requiring the caller to enter the dev shell. This pair does not define the builder/test-subject boundary; `establish-testing-operations` owns that boundary and its evidence.

### Keep documentation explanatory rather than executable

`tooling.md` remains the catalogue of roles, selections, scope, and authority. It will reference `nix/tooling.nix`, flake outputs, lock files, host modules, or external bootstrap documentation as appropriate. It will not duplicate package versions, hashes, or the complete Nix package list. The executable environment is tested mechanically; semantic catalogue quality is reviewed through the configured `ops` lens.

### Make entry simple and optional to automate

The documented entry point is `nix develop`. An optional `.envrc` may contain only `use flake` for users of direnv/nix-direnv; it is convenience, not a prerequisite. Repository commands remain explicit and can be run as `nix develop --command <command>` in automation.

## Enforcement design

### `tests/tooling/environment.bats`

The Bats source executes inside the Nix development shell. It compares implementation-derived systems with the independent supported-system manifest; asserts that the shared package, default dev shell, native command contract, and bounded platform-adapter metadata evaluate for every required system; executes each native contract through the available local or remote Nix store; verifies the current shell exposes each declared direct command; confirms the Darwin `ssh` command delegates to the catalogue-selected platform executable; compares the Nix registry with the independent command inventory; dry-runs every registered Make operation and rejects a primary command that is neither managed nor the explicit Nix bootstrap; checks Specbase reports the selected compatible version; and inspects each shell derivation's real inputs for the shared package. Missing commands, removed systems, failed native contracts, undeclared adapters, operation-command drift, command-inventory drift, or shell-input drift produce ordinary non-zero Bats failures.

The source proves command availability and package/shell wiring. It does not prove the semantic correctness of every third-party tool, remote-builder readiness beyond executing the requested derivation, or app-specific behavior.

### `ops` review of `tooling-catalogue`

The Ops lens compares changed direct tool selections with `tooling.md` and their named executable authorities. It checks that roles are clear, external/bootstrap exceptions are explicit, and versions are not duplicated in prose. This is judgment over catalogue meaning, not a Markdown string-equality check.

The review does not require incidental utilities or transitive closure members to receive catalogue entries.

## Risks / Trade-offs

- **Specbase is not in nixpkgs** -> Package the selected npm release with fixed source/dependency hashes and make its version an explicit conformance assertion.
- **Some packages differ across Darwin and Linux** -> Keep one role/command contract with per-system package selection inside `nix/tooling.nix`; fail evaluation when a supported system cannot supply it.
- **macOS denies Nix OpenSSH access to LAN hosts** -> Keep `ssh` Nix-provided at the command boundary but delegate through a documented Darwin-only adapter to Apple `/usr/bin/ssh`; mechanically reject an unbounded or Linux-side adapter.
- **A large dev shell becomes slow** -> Include direct operator tools only and keep runner-specific dependencies in app/check closures.
- **The catalogue and Nix registry drift** -> Mechanically test the executable environment and use the Ops review lens for semantic catalogue updates.
- **Automation assumes the dev shell** -> Require apps/checks to carry runtime dependencies and use `nix develop --command` only where the complete operator environment is intentional.
- **The current generated Specbase skills mention legacy enforcement** -> Treat current CLI artifact instructions and compact `enforcement.yaml` as authoritative; skill refresh remains separate agents-plane work.

## Migration Plan

1. Add `nix/tooling.nix` with supported systems, direct packages, and the pinned Specbase package.
2. Expose `repo-tools` packages and default development shells from `flake.nix` using a local system helper.
3. Add and execute the Bats environment conformance source through `nix develop`.
4. Update `tooling.md` and README setup guidance, preserving Nix and Pi as explicit external prerequisites.
5. Replace ambient tool invocations where a pinned flake path is available, without changing deployment semantics.
6. Validate and archive `ops.tooling`, then apply `establish-testing-operations` using the shared Bats/tool definitions.

Rollback removes the tool outputs and restores the prior ambient-tool documentation. It does not change a deployed host generation.
