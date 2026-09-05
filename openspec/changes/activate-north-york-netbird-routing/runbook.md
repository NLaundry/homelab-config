# User runbook: activate North York NetBird routing

## Why you are needed

This is the first Stack 1 proposal that intentionally opens a remote path into the North York LAN. You supply distinct authorized and unauthorized test identities, maintain local recovery access, and approve the live policy boundary.

## Prerequisites

Before activation, confirm:

- you have a working local OPNsense administration/console path
- the OPNsense NetBird peer is connected and its Ansible run is unchanged
- the North York OpenTofu plan currently has no changes
- encrypted state backup is current
- DNS names are not being used for tests; use verified Estate IP addresses

Prepare two connected NetBird peers:

1. an administrator test peer included in the explicit source group
2. a non-administrator test peer excluded from that group

Do not use NetBird's catch-all group as the administrator source.

## When to act

### Tasks 1.2 and 4.1: confirm group membership and plan

Review the exact administrator-peer list and North York destination resource. Confirm the plan contains only:

- intended peer membership in the administrator/router groups
- one North York Network router assignment
- explicit metric and masquerading
- one North York resource group
- one unidirectional administrator-to-resource policy

Reject any DNS, SSH, second-site, reverse-direction, catch-all, or unrelated policy change.

### Tasks 2.3 and 4.2: guard the router mutation

Keep the local OPNsense session open. Confirm that a firewall savepoint exists before the pass rule is enabled and that automatic rollback remains armed. Immediately verify local management after Ansible applies the bounded `wt0` rule.

Do not cancel the savepoint yet.

### Tasks 4.3–4.4: perform positive and negative checks

After OpenTofu activation:

1. From the authorized peer, run the bounded route/ICMP/TCP probes against the selected North York IP targets.
2. From the non-administrator peer, attempt the same safe probes.
3. Confirm the authorized probes succeed and the non-administrator probes fail.
4. Confirm ordinary North York LAN access and OPNsense administration still work.

Stop and allow/revert the firewall savepoint if any result differs.

### Task 4.5: approve savepoint commitment

Only after all checks pass, approve cancellation of automatic firewall rollback. Review the final OpenTofu plan and Ansible run; both must report no change. Confirm the encrypted state backup was refreshed.

### Tasks 5.1–5.2: perform the rollback drill

Expect a temporary loss of remote routed access during this drill. Execute in order:

1. disable the NetBird access policy
2. remove or disable the Network router assignment
3. prove routed access is gone
4. disable the OPNsense pass rule
5. confirm OPNsense remains an enrolled, connected peer
6. confirm local router/LAN operation remains healthy
7. reapply the accepted activation and repeat positive and negative checks

Do not remove the peer or regenerate a setup key.

## Stop conditions

Stop immediately if:

- local OPNsense management degrades
- the non-admin peer reaches a North York resource
- the admin peer cannot reach the bounded target
- source/destination scope is broader than planned
- masquerading or route metric is absent
- Scarborough, DNS, NetBird SSH, or public ingress appears in the plan
- state or credential material appears in evidence

## Evidence to record

Record sanitized peer/group IDs, resource names/CIDRs, plan action counts, savepoint revision, probe targets/results, rollback timestamps, and final no-change summaries. Never record PATs, API secrets, setup keys, state bodies, or packet captures containing unrelated traffic.
