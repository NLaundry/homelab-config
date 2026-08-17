## 1. Shared Nix tool set

- [x] 1.1 Run current compact-enforcement instructions, inventory direct commands invoked by Make, tests, deployment, specification, and Ansible workflows, and classify Nix/Pi as explicit bootstrap exceptions rather than ambient omissions.
- [x] 1.2 Add `nix/tooling.nix` with the supported operator systems and one shared direct package definition, using per-system selections only where Darwin and Linux package names differ.
- [x] 1.3 Package the selected Specbase npm release through Nix with fixed source/dependency hashes and confirm its CLI reports the compatible selected version without using the global npm installation.
- [x] 1.4 Expose `packages.<system>.repo-tools` and `devShells.<system>.default` from `flake.nix` through a small local system-mapping helper, without adding flake-utils.
- [x] 1.5 Confirm all declared system outputs evaluate, build the current aarch64-darwin tool package/dev shell, and record that x86_64-linux execution remains derivation-carried rather than a global builder installation.

## 2. Repository integration and documentation

- [x] 2.1 Verify the pinned nixpkgs deployment adapter is usable from aarch64-darwin and expose a pinned flake path for it without changing remote build or activation semantics.
- [x] 2.2 Replace repository-owned ambient invocations that now have a pinned flake authority, while keeping apps/checks responsible for their own runtime closures rather than assuming an entered dev shell.
- [x] 2.3 Update `tooling.md` so direct selections point to `nix/tooling.nix`, flake outputs, lock files, or explicit external prerequisites; do not add incidental or transitive tools.
- [x] 2.4 Update `README.md` with the Nix bootstrap prerequisite, `nix develop`, `nix develop --command`, supported systems, and the distinction between operator tooling and builder capabilities.

## 3. Paired evidence

- [x] 3.1 Add `tests/tooling/environment.bats` to evaluate the shared package/default-shell outputs for every supported system and assert every declared direct command in the current dev shell.
- [x] 3.2 Add controlled fixture coverage proving the Bats source fails for a missing direct command and for drift between the shared package definition and default dev shell, then restore the conforming fixture.
- [x] 3.3 Run the environment suite through the Nix development shell and confirm it does not resolve Specbase, Bats, Make, or other managed commands from Homebrew/global npm paths.
- [x] 3.4 Execute the `ops` catalogue review over `tooling.md`, confirming clear roles/authorities, explicit Nix/Pi exceptions, and no duplicated version truth.

## 4. Validation and testing-stack handoff

- [x] 4.1 Confirm every compact source exists and passes its native test or review procedure; compact bindings require no planned/active status transition.
- [x] 4.2 Run `nix flake check`, `specbase validate establish-reproducible-repository-tooling --type change --strict`, current-spec strict validation, and strict coverage.
- [x] 4.3 Confirm no development package was added to the NAS system configuration and no builder is required to install the complete `repo-tools` environment globally.
- [x] 4.4 Rebase `establish-testing-operations` onto the shared Bats/tool definitions so that change owns harness/verification entry points and VM derivations, not a second general repository package list.
