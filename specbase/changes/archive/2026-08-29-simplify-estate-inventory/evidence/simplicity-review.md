# Simplicity review

## Result

The implementation now consists of:

- `estate.yaml`: 26 lines of operator inventory;
- `tests/estate/inventory.bats`: one 38-line focused check;
- `make estate-check`: one direct update command.

Removed surfaces include six Nix Estate files, generated graph and diff logic, reconciliation and mutants, graph exports, the Estate flake derivation, and the six-test registry suite. No generated Estate model or runtime consumer remains.

## Runtime boundary

The NAS top-level derivation before and after the simplification is identical:

`/nix/store/3kk8ndgvrdqzplgvimj9q2xn99bqnbrk-nixos-system-NASty-26.05.20260804.04607e1.drv`

No host module or activation operation changed. The YAML is descriptive inventory and does not drive deployment.

## Known boundary

The focused check proves YAML shape, internal site/host references, and the catalogued current values. It does not prove that the inventory matches a live host. Existing Nix evaluation, VM, and live checks retain responsibility for their own configuration and service claims.

## Rollback

Revert this change to restore the typed graph implementation. No NAS rollback or activation is required because the system derivation is unchanged.
