# Enable North York LAN routing

## What

Use the enrolled OPNsense peer to let an explicit administrator group reach
North York LAN resources. Deny peers outside that group.

## Why

Clientless LAN hosts need a routing peer. OPNsense provides that boundary;
masquerading avoids adding return routes to every host.

## Before you start

**Draft: activation declarations, firewall tasks, and routing probes do not exist
yet.** Complete the [unrouted enrollment](opnsense-netbird-enrollment.md) first.

Require:

- A no-change baseline plan before introducing activation changes.
- A repeated enrollment run with no changes or new identity.
- A current encrypted state backup and protected OPNsense backup.
- One uniquely identified, connected OPNsense peer.
- Working local administration and independent console recovery.
- Two connected test peers: one administrator and one outside the allowed group.
- A supported firewall savepoint with enough time for all checks.

Do not activate without the second test peer. A successful administrator probe
cannot prove that other peers are denied.

## 1. Review the access boundary

### 1.1 Review the intended traffic and configuration

Confirm the exact administrator members, destination resources, protocol/port
list, overlay source alias, route metric, and probe timeouts.

The planned configuration uses:

- Destination `10.10.10.0/24`, confirmed against `estate.yaml`.
- The dedicated router group through `netbird_network_router.peer_groups`.
- An explicit metric and `masquerade = true`.
- An explicit administrator source group and resource destination group.
- One-way initiation from administrators, with stateful return traffic.
- One Ansible-owned pass rule: ingress `wt0`, selected overlay source, North York
  LAN destination. Limit it to the approved traffic.

Reject catch-all source groups, any/any rules, WAN ingress, reverse initiation,
second-site changes, DNS management, setup keys, or any unapproved replacement.

### 1.2 Check existing policies and routes

Inspect all effective policies and routes, not only the new declarations. An
existing route or policy could make a prepared firewall rule active earlier than
expected. Resolve that conflict before proceeding.

## 2. Stage the activation

### 2.1 Validate and review the activation plan

Before any live change, pass the implemented static checks. The refresh-only
baseline plan must show no changes before activation declarations are added.
Then generate and review the normal activation plan. Do not enable the firewall
rule until that plan contains only the approved changes.

### 2.2 Enable the firewall rule and recheck management

1. Confirm local management and arm the firewall savepoint.
2. Enable the reviewed persistent pass rule through Ansible.
3. Recheck local management. Stop and revert if it degrades.

### 2.3 Apply routing and keep rollback active

1. Apply the reviewed OpenTofu group membership, router assignment, metric,
   masquerading, and access policy through the secret adapter.
2. Keep the savepoint active while running the checks below.

Ansible must not manage remote NetBird policy. OpenTofu must not manage the
OPNsense firewall. If either step fails, use the rollback order below.

Do not cancel automatic firewall rollback early merely to gain more test time.
Choose a supported test window before starting.

## 3. Check both allowed and denied access

### 3.1 Select probes and expected results

Use confirmed IP addresses, not DNS. Select bounded route, ICMP, and TCP probes;
use read-only endpoints and perform no login or file write.

| From | Check | Expected result |
|---|---|---|
| Administrator peer | Route and approved traffic to NASty at `10.10.10.11` | Succeeds |
| Administrator peer | Approved safe OPNsense endpoint at `10.10.10.1` | Succeeds |
| Non-administrator peer | The same North York destinations and ports | Denied |
| Local LAN | Existing management and ordinary services | Still work |

### 3.2 Verify test peers and run both checks

Confirm both test peers are connected and otherwise functional. An offline peer
or a dead endpoint is not proof of policy denial. Confirm that Scarborough and
other unrelated access remain unchanged.

The planned `tests/verify/netbird-routing.bats` must run on the selected
administrator peer only after implementation. Do not add it blindly to the
normal NAS post-deploy suite; it needs a specific network identity. Run the
negative check from the separate non-administrator peer.

### 3.3 Check the routing peer and logs

Confirm that OPNsense remains the only routing peer. LAN hosts do not become
NetBird peers automatically. Check the available sanitized policy/edge logs;
masquerading hides the original overlay source address from destination hosts.

## 4. Accept the activation

Cancel the savepoint rollback only after every check passes. Save a new encrypted
state backup. Require a no-change OpenTofu plan and Ansible run.

Record non-secret peer/group IDs, approved traffic, savepoint identifier, and
positive/negative results. Do not record credentials or full state.

## Stop or recover

Use the planned source-controlled toggles through OpenTofu and Ansible for normal
activation and withdrawal. Do not use routine dashboard edits.

### 1. Restore the unrouted boundary

On failed checks or unexpected access, restore the unrouted boundary in order:

1. Disable the NetBird access policy.
2. Remove or disable the Network router assignment.
3. Prove the routed path is gone.
4. Disable or revert the persistent OPNsense pass rule.

Preserve the connected peer, `wt0`, baseline Network/resource/group, and encrypted
state. Do not re-enroll merely to undo routing. If a control plane is unavailable,
use the independent local recovery path to close access; do not leave a known
exposure open while waiting for normal automation. Reconcile emergency edits with
source configuration before the next apply.

### 2. Prove rollback and reactivation

In an approved window, prove rollback and then reactivate with the same checks.
Do not claim this drill occurred merely because the procedure exists.

OPNsense is a single routing failure point. Its failure removes remote LAN access;
local recovery must remain independent of that route.

## Source

[Planned change](../../openspec/changes/activate-north-york-netbird-routing/).
