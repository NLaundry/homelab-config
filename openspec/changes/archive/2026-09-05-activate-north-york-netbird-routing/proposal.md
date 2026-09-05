## Why

OPNsense is enrolled but North York LAN access is still disabled. Enable the existing routing peer for explicitly selected administrator devices without adding another router-management framework.

## What Changes

- Assign the existing OPNsense peer directly to the North York Network with masquerading and an explicit metric.
- Reuse the existing LAN resource and resource group; add one administrator source group and a one-way access policy.
- Enable the required plugin routing settings through Ansible while keeping NetBird DNS and SSH disabled.
- Use the plugin's built-in firewall integration. Add no router group, reusable module, manual interface assignment, or persistent firewall rules.
- Replace the two network static-check scripts with one practical `tests/verify/iac-connectors.bats` file for authenticated API reads and an explicitly selected routed connection check.
- Review one activation plan and verify one useful connection from outside the North York LAN. Retain a short disable-policy/router rollback procedure, not a rollback drill or backup project.

## Capabilities

### New Capabilities

- `service/network/north-york-access`: selected administrators can reach North York resources; other peers are not authorized.
- `estate/network/north-york-routing`: OPNsense is the single North York routing boundary.
- `lifecycle/netbird-routing`: activation can be withdrawn without removing the enrolled peer.

### Modified Capabilities

- `configuration/netbird`: directly assign OPNsense and enable explicit administrator access.
- `configuration/opnsense-netbird`: enable plugin-managed forwarding without DNS or SSH takeover.

## Verification intent

- Authenticated NetBird and OPNsense GET requests prove the automation connections still work. Ping alone does not prove API authentication.
- A bounded TCP connection to an approved LAN service from an authorized off-LAN peer proves routed service reachability. ICMP is optional; a blocked ping is not automatically a routing failure.
- Review all effective policies/routes for conflicting access. A successful connection does not prove unauthorized denial; no second test peer or denial-test claim is required for this small change.
- Run ordinary formatting, validation, and Ansible syntax commands during implementation, without maintaining duplicate structural-test scripts.

## Impact

Changes the existing OpenTofu root and OPNsense playbook, replaces `tests/iac/netbird-static-check` and `tests/ansible/opnsense-static-check` with one connector test file, and shortens the routing runbook. No DNS, DHCP, PKI, Scarborough, setup-key, or public-ingress changes.
