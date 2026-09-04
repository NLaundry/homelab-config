## Why

The preceding prefixes leave OPNsense safely enrolled and the North York Network declarative but unrouted. This final Stack 1 change activates the smallest useful routing boundary so authorized NetBird administrators can reach North York LAN resources while other peers remain denied.

## What Changes

- Discover the uniquely enrolled North York OPNsense peer through the official NetBird provider and place it in the managed router group.
- Assign that group as the North York Network router with masquerading enabled and an explicit route metric.
- Create a managed North York resource destination group and an explicit one-way administrator-to-LAN policy.
- Activate only the Ansible-owned OPNsense `wt0`-to-North-York-LAN firewall rule needed by the routed path, under a savepoint.
- Verify authorized reachability to bounded North York targets and verify denial from a peer outside the administrator source group.
- Keep clientless LAN hosts represented as routed resources rather than NetBird peers; do not add DNS or automatic host enumeration.
- Provide rollback that disables NetBird policy/router assignment before removing the active OPNsense pass rule while preserving peer enrollment.

## Planes

### Service

- `service.network.north-york-access`: authorized administrator peers can reach selected North York LAN resources through NetBird while unauthorized peers cannot (new).

### Estate

- `estate.network.north-york-routing`: North York OPNsense is the routing boundary between the NetBird overlay and North York LAN resources (new).

### Configuration

- `configuration.netbird`: replace the unrouted baseline with the selected router-group assignment, masquerading, resource grouping, and explicit administrator policy (modified from the baseline prefix).
- `configuration.opnsense-netbird`: activate the bounded persistent OPNsense firewall realization for routed NetBird traffic (modified from the enrollment prefix).

### Lifecycle

- `lifecycle.netbird-routing`: routing activation and rollback preserve local router management, unrelated services, and the enrolled peer identity (new).

## Enforcement intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| `authorized-north-york-access` | test | `tests/verify/netbird-routing.bats` | From an authorized NetBird peer, bounded probes reach the selected North York LAN targets through the routing peer. |
| `unauthorized-north-york-access-denied` | manual | `docs/operations/netbird-routing.md#negative-access-check` | A peer outside the administrator group cannot reach the North York resource while the authorized probe still succeeds. |
| `north-york-opnsense-routes-overlay` | command | `tests/iac/netbird-static-check` | Evaluated IaC connects the North York Network to its dedicated OPNsense router group and no other site/router. |
| `north-york-routing-failure-boundary` | review | `estate` | Estate review confirms that the declared route depends on the North York router and does not imply independent client peers or a second-site path. |
| `north-york-routing-assigned` | command | `tests/iac/netbird-static-check` | The evaluated router resource is enabled with explicit metric and masquerading. |
| `north-york-admin-policy-explicit` | command | `tests/iac/netbird-static-check` | The evaluated policy names explicit source and destination groups and grants no reverse initiation. |
| `opnsense-routed-rule-bounded` | test | `tests/ansible/opnsense-netbird-contracts.bats` | The active role-owned rule is limited to `wt0`, the NetBird overlay source, and the selected North York LAN destination. |
| `netbird-routing-activation-safe` | manual | `docs/operations/netbird-routing.md#activation` | Staged firewall and OpenTofu activation retains local management and passes positive/negative checks before the savepoint is committed. |
| `netbird-routing-rollback-safe` | manual | `docs/operations/netbird-routing.md#rollback` | Policy and router assignment are removed before the pass rule while peer health, LAN administration, and unrelated services remain intact. |

## Impact

- Modifies the NetBird OpenTofu module/root, North York router/resource groups, router assignment, and policy.
- Modifies the Ansible OPNsense NetBird role to activate one bounded routed firewall rule.
- Adds bounded live verification and an activation/rollback runbook.
- Makes North York LAN resources reachable to the selected administrator group; adds no DNS, Scarborough, NetBird SSH, public exposure, or per-host NetBird agents.
