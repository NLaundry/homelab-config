## Why

The Estate still describes the current location as a generic `home` site and omits the router, access point, and Proxmox host already present in operational inventory. Stack 1 needs a truthful North York anchor before IaC assigns network ownership or routing roles.

## What Changes

- Rename the current Estate site from `home` to `north-york` and retain NASty at its existing address.
- Catalogue the existing North York OPNsense router, OpenWrt access point, and Proxmox host at their current addresses.
- Record the current North York LAN as `10.10.10.0/24` so later NetBird and firewall configuration consume one declared boundary.
- Keep file sharing placed on NASty.
- Do not add Scarborough or any future-site placeholders.
- Retire the Estate model's value-copying test binding and use the Estate review lens for the inventory's actual contents.
- Remove the obsolete site-name assertions from the shared inventory test rather than replacing them with North York values; retain only checks still required by unrelated surviving bindings and add no automated Estate-content enforcement.

## Planes

### Estate

- `estate.model`: keep the human-readable Estate inventory aligned with the currently catalogued North York site, hosts, and service placement (modified).

## Enforcement intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| `inventory-locates-estate` | review | `estate` | Estate review confirms that the human-readable inventory truthfully locates the current North York hosts and service placement without duplicating those values in a test. |

## Impact

- Updates `estate.yaml`, retires one Estate binding, and removes the obsolete site-name assertion from a shared test that remains owned by other governed pairs.
- Modifies the existing `estate.model` governed pair without creating a new topology hierarchy or bespoke enforcement.
- Changes no live host, network, service, Ansible inventory, or NetBird object.
