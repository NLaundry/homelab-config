## Why

The repository records selected tools in `tooling.md`, but most operator commands still depend on whatever happens to be installed globally. A Nix-defined repository tool set and development shell will make routine planning, testing, deployment, and fleet work reproducible while preserving the catalogue as the human explanation of each selection.

## What Changes

- Add `nix/tooling.nix` as the executable authority for direct repository tools available from nixpkgs or explicitly packaged from pinned upstream sources.
- Expose the shared tool set through flake packages and default development shells for the supported operator systems.
- Include tools directly invoked by repository operations and conformance suites, including Make, Specbase, Bats, shell tooling, SSH, and Ansible; keep Nix itself and Pi documented as bootstrap/external prerequisites, and document the bounded Darwin adapter to platform OpenSSH required by macOS local-network security.
- Keep runner-only dependencies inside their app or derivation closures and keep Linux/KVM host capabilities in `ops.testing`, rather than installing every tool globally on a builder.
- Keep `tooling.md` as the role/rationale catalogue and point each selected tool at its executable authority instead of duplicating versions.
- Make this change a prerequisite of `establish-testing-operations`, which will consume the shared Bats/tooling environment when defining harness and verification entry points.

## Planes

### Ops

- `ops.tooling`: the selected repository tool set, supported operator development shells, and human tooling catalogue (new).

No behavioral, architectural, code-quality, or agents truth changes. Tool replacement and development-environment packaging are Ops concerns; existing testing-isolation architecture continues to own the operator/builder/test-subject boundaries.

## Spec pairs

- `ops.tooling` -> new pair governing the Nix-defined repository tool set, operator development shell, and catalogue authority.

## Enforcement intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| `repository-tool-set` | `test` | `tests/tooling/environment.bats` | A clean Nix environment exposes the declared direct command set from one shared Nix package definition. |
| `operator-dev-shell` | `test` | `tests/tooling/environment.bats` | Each supported operator system evaluates a default dev shell and the current operator shell supplies its required commands. |
| `tooling-catalogue` | `review` | `ops` | The catalogue assigns direct selections to clear roles and executable authorities without duplicating version truth. |

## Impact

- Adds `nix/tooling.nix`, flake package/dev-shell outputs, and a tooling conformance suite.
- Updates `tooling.md` and repository setup documentation.
- Pins explicitly packaged non-nixpkgs tools through Nix source hashes while retaining `flake.lock` as the nixpkgs version authority.
- Does not install development tools globally on the NAS or future test builder.
- Becomes a prerequisite for `establish-testing-operations`; no deployed homelab generation changes are required.
