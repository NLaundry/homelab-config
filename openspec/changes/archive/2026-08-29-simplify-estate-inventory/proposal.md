## Why

The typed Estate graph is much larger than the inventory problem it solves and mostly tests parallel metadata. The homelab needs one obvious, human-maintained place to answer where sites, hosts, services, addresses, and host details are.

## What Changes

- **BREAKING:** Remove the typed Nix Estate schema, graph, diff, fixture, reconciliation, flake export, and dedicated mutation suite.
- Add one root `estate.yaml` inventory with simple maps for sites, hosts, and services.
- Record host details such as hostname, site, addresses, and storage directly in that file; allow service details such as URLs to be added when they exist.
- Add one small inventory check and one documented command to catch malformed YAML and missing top-level sections.
- Remove Estate bindings that claim graph or realization reconciliation.

## Planes

### Estate
- `estate.model`: replace typed graph requirements with the simple site, host, and service inventory contract (modified).
- `estate.nas-storage`: remove graph and reconciliation enforcement; its existing topology review remains (modified enforcement only).

### Configuration
- `configuration.nas-realization`: record the selected NAS inventory address without turning the inventory into deployment authority (modified).

### Governance
- `governance.estate-registry`: replace registry machinery requirements with a minimal human-maintained YAML and update workflow (modified).

## Enforcement intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| `inventory-locates-estate` | `test` | `tests/estate/inventory.bats` | The single YAML parses and contains the current site, host, and service references. |
| `nas-inventory-address` | `test` | `tests/estate/inventory.bats` | The inventory records the selected NAS LAN address. |
| `single-estate-inventory` | `test` | `tests/estate/inventory.bats` | The repository has one readable inventory with the expected top-level maps. |
| `inventory-maintained-with-change` | `review` | `governance` | Review checks that topology or address changes update the inventory in the same change. |

## Impact

- Adds `estate.yaml` and a small focused check.
- Removes `nix/estate/` and the Estate-specific flake library/check surface.
- Replaces `tests/estate/registry.bats` with a minimal inventory test.
- Simplifies the current Estate and Governance specifications without changing the running NAS.
