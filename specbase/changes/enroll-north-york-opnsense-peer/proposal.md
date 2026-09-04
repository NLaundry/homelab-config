## Why

The North York NetBird Network cannot route until OPNsense is a healthy enrolled peer, but router mutation and one-use credential handling belong outside OpenTofu state. This change establishes the reusable Ansible-managed router side while keeping the LAN unrouted until a separately reviewed activation.

## What Changes

- Restructure Ansible inventory and variables around a reusable site/router role while adding only the North York OPNsense host.
- Pin `oxlorg.opnsense` and establish authenticated API preflight against the installed firmware.
- Require a supported OPNsense release and official `os-netbird` package before mutation.
- Install and configure `os-netbird`, disable NetBird-managed DNS and NetBird SSH for this prefix, assign `wt0`, and keep persistent OPNsense settings under Ansible ownership.
- Generate a one-use NetBird setup key outside OpenTofu, enroll the router, verify peer health, and revoke/delete the key.
- Prepare narrowly scoped dormant OPNsense aliases/rules required by later routed traffic using firewall savepoints, without assigning a NetBird Network router.
- Preserve existing LAN administration and provide an explicit uninstall/disconnect rollback.

## Planes

### Governance

- `governance.network-iac`: Ansible is the exclusive repository authority for managed OPNsense package, interface, firewall, and service configuration while OpenTofu remains the NetBird control-plane authority (modified from the preceding stack member).

### Configuration

- `configuration.opnsense-netbird`: North York OPNsense runs the supported official NetBird plugin as an enrolled peer with bounded settings and interface realization (new).

### Lifecycle

- `lifecycle.netbird-enrollment`: enrollment is preflighted, idempotent, consumes one ephemeral setup key, and can be disconnected or uninstalled without activating LAN routing (new).

## Enforcement intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| `opnsense-configuration-authority` | test | `tests/ansible/opnsense-netbird-contracts.bats` | OPNsense resources occur only in the Ansible role and no OpenTofu OPNsense provider/resource is introduced. |
| `opnsense-automation-reusable` | command | `tests/ansible/opnsense-static-check` | Inventory, site variables, role defaults, collection lock, and syntax resolve for North York without embedding a second site. |
| `opnsense-netbird-plugin-supported` | manual | `docs/operations/opnsense-netbird-enrollment.md#preflight` | Live firmware/package/API observations satisfy the supported-version gate before mutation. |
| `opnsense-netbird-peer-bounded` | test | `tests/ansible/opnsense-netbird-contracts.bats` | Desired plugin settings enable the peer while disabling DNS, SSH, and undeclared broad firewall access. |
| `opnsense-wt0-assigned` | manual | `docs/operations/opnsense-netbird-enrollment.md#post-enrollment-verification` | The live router reports assigned `wt0`, a running NetBird service, and connected management status. |
| `netbird-enrollment-preflighted` | manual | `docs/operations/opnsense-netbird-enrollment.md#preflight` | Read-only checks establish compatibility and a recoverable management path before changes. |
| `netbird-enrollment-idempotent` | manual | `docs/operations/opnsense-netbird-enrollment.md#post-enrollment-verification` | A second Ansible run reports no change and does not create another peer or setup key. |
| `opnsense-peer-rollback` | manual | `docs/operations/opnsense-netbird-enrollment.md#rollback` | The router can disconnect/remove the peer configuration while retaining verified LAN administration. |

## Impact

- Adds a pinned Ansible collection manifest, North York site variables, reusable OPNsense NetBird role/playbook, static checks, and an enrollment runbook.
- Mutates the live North York OPNsense package, plugin settings, interface assignment, and bounded dormant firewall preparation.
- Creates one NetBird peer identity, but no `netbird_network_router`, routed policy, DNS distribution, Scarborough configuration, or LAN reachability change.
