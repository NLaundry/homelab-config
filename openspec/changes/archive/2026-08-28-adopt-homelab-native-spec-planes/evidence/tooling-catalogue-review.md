# Operator tooling catalogue review

- **Reviewed:** 2026-08-28 UTC
- **Revision:** `32a5772200a82509db25a27647a28ee7ae3590b3` plus the uncommitted plane migration
- **Lens:** Governance
- **Source:** `tooling.md`

## Result

The catalogue identifies each selected tool's role, scope, and executable authority. Exact package versions and hashes remain owned by `flake.lock`, `nix/tooling.nix`, and the platform rather than being copied into the catalogue. It distinguishes bootstrap prerequisites, the shared operator set, derivation-carried tools, and roles with no current selection.

The cross-system executable checks passed in `evidence/execution/tooling-environment.log`, including inventory drift, missing command, unregistered operation, supported-system removal, and shell-input mutants.

## Limitations

This review judges catalogue role/scope/authority semantics. It does not independently prove package contents, versions, command behavior, or availability; those claims remain with evaluated/build evidence.
