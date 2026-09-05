# Rollback

Rollback is one revert of the Estate-registry delivery commit. The revert removes:

- `nix/estate/` schema, registry, validator, diff, fixtures, and reconciliation,
- `lib.estateGraph` and Estate flake check integration,
- `tests/estate/registry.bats` and its observation declarations,
- graph/reconciliation bindings added to the Estate and Governance pairs.

The pre-change `estate/nas-storage` review binding remains the fallback for physical-placement residue.

No host rollback is required. This change evaluates Nix data, builds check artifacts, and reads existing NixOS configuration; it does not activate a generation or alter service, account, firewall, mount, pool, or host placement configuration.
