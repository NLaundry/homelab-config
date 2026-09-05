## Context

The preceding prefix leaves North York OPNsense connected as a unique NetBird peer, `wt0` assigned, route-capable plugin settings prepared, and no active overlay-to-LAN rule. OpenTofu owns an unrouted North York Network, LAN resource, and empty router group. This change crosses the security boundary for the first time: remote overlay traffic can reach clientless North York LAN hosts.

The intended current scope is administrator access to the North York LAN. DNS, reverse initiation from LAN clients, user/service tiers, Scarborough, NetBird SSH, and public ingress remain outside Stack 1.

## Goals / Non-Goals

**Goals:**
- Make the enrolled OPNsense peer the North York Network router.
- Preserve source simplicity with masquerading enabled.
- Allow an explicit administrator peer group to initiate traffic to the North York LAN resource.
- Deny peers outside that source group.
- Stage OPNsense and NetBird changes so rollback preserves management and enrollment.
- Prove useful reachability to bounded known targets.

**Non-Goals:**
- Turn LAN hosts into NetBird peers or discover them automatically.
- Add friendly DNS names or NetBird nameservers.
- Permit North York LAN clients to initiate arbitrary overlay sessions.
- Add Scarborough or a redundant routing peer.
- Enable NetBird SSH or public exposure.

## Decisions

### Router group assignment

Resolve the uniquely named enrolled OPNsense peer with the official provider data source and manage its membership in the dedicated North York router group. Assign the group—not a copied peer ID—as `peer_groups` on `netbird_network_router`, allowing a later site module instance to follow the same shape. Duplicate or disconnected matches block planning.

Use an explicit route metric supplied by the module and `masquerade = true`. Masquerading avoids return-route changes on every North York host and keeps the router as the LAN-visible source. Original overlay source visibility at destination hosts is an accepted trade-off; NetBird and OPNsense logs retain the policy/edge observations available for this small admin-only deployment.

### Explicit source and destination groups

Inventory the intended administrator device peers and manage them in a dedicated source group. Add the North York LAN resource to a dedicated destination group. Create one enabled, unidirectional accept rule from the administrator group to the resource group using the required protocols. Stateful return traffic is allowed; reverse initiation is not implied.

Do not use NetBird's catch-all group as the policy source. User/service-tier policies are later changes.

### Two-control-plane staged activation

1. Confirm local OPNsense management and create a firewall savepoint.
2. Enable the Ansible-owned pass rule scoped to ingress `wt0`, the NetBird overlay source range/alias, and the North York LAN destination.
3. Apply OpenTofu group membership, router assignment, masquerading, and policy.
4. Run positive and negative probes.
5. Cancel automatic firewall rollback only after every required check passes.

The dormant OPNsense rule alone exposes nothing before the NetBird route/policy exists. If an OpenTofu step fails, disable/revert the pass rule. Ansible never manages the remote NetBird router or policy object.

### Bounded verification targets

Use Estate-derived North York addresses rather than DNS. The live Bats probe runs from a selected administrator NetBird peer and checks route presence plus bounded ICMP/TCP connectivity to NASty and, where safe, the OPNsense LAN management endpoint. It performs no login or write. A separate peer outside the administrator group performs the negative check because CI cannot honestly simulate a distinct NetBird identity.

“Reachable hosts” means routed IP resources. Only OPNsense appears in the NetBird peer list; LAN hosts remain clientless resources until individually enrolled in a later change.

### Rollback order

Disable the NetBird policy, then remove/disable the Network router assignment, verify the routed path is gone, and finally revert/disable the OPNsense pass rule. Preserve the enrolled peer, `wt0`, baseline Network/resource/group, and encrypted state so activation can be retried without re-enrollment.

## Verification design

- `tests/iac/netbird-static-check` evaluates module fixtures and sanitized plan JSON. It asserts one North York router group, the uniquely selected peer, enabled router assignment, explicit metric, masquerading, explicit admin/resource groups, and a one-way policy. It rejects catch-all sources, reverse initiation, second-site data, setup keys, and DNS resources. It does not prove live packet flow.
- `tests/ansible/opnsense-netbird-contracts.bats` asserts the active persistent rule is role-owned and limited to `wt0`, the selected overlay alias, and the Estate-derived North York destination. It rejects any/any and WAN-facing rules. It does not evaluate live pf state.
- `tests/verify/netbird-routing.bats` runs with Bats on an explicitly selected authorized NetBird peer. It uses bounded route, ICMP, and TCP probes and fails on timeout or wrong endpoint. It does not prove unauthorized denial.
- `docs/operations/netbird-routing.md` carries activation, negative-access, and rollback procedures. Sanitized evidence records peer/group identifiers, plan summaries, savepoint revision, and probe results without credentials or full state.
- Manually inspect the declared topology to confirm OPNsense is the single routing failure boundary and no second-site path or independent client peers are implied; this does not substitute for packet probes.

## Risks / Trade-offs

- [Activation can expose the full LAN] -> Use an explicit destination resource group, dedicated admin source group, and both positive and negative checks.
- [A firewall mistake can lock out management] -> Require local path, savepoint, staged activation, and delayed savepoint cancellation.
- [Masquerading hides original source IP from LAN hosts] -> Accept for initial simplicity; retain edge logs and revisit only for a concrete audit requirement.
- [An administrator peer is lost or compromised] -> Keep source membership explicit and removable through OpenTofu; do not use `All`.
- [Router/plugin failure removes remote LAN access] -> Record OPNsense as the single routing failure boundary; local LAN operation remains independent.
- [Positive-only automation misses policy leaks] -> Require a real non-admin negative probe before committing the activation.

## Migration Plan

1. Extend module/test fixtures for router, source/destination groups, masquerade, and policy without touching live state.
2. Select and verify the unique OPNsense and administrator peers; stop on ambiguity or disconnected router state.
3. Run static checks, a refresh-only plan, and a normal plan; reject replacement or unrelated changes.
4. Create the OPNsense savepoint and enable the bounded pass rule through Ansible while continuously checking local management.
5. Apply the OpenTofu activation and run authorized positive probes plus the non-admin negative check.
6. Cancel the savepoint rollback only after all checks pass; back up encrypted OpenTofu state and require a final no-change plan/playbook.
7. To roll back, disable policy, remove/disable router assignment, prove routed access is gone, then disable the OPNsense pass rule while retaining peer enrollment.
