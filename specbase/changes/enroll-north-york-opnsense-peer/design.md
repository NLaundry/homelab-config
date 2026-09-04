## Context

The preceding stack prefix leaves a North York NetBird Network and LAN resource under OpenTofu with no router assignment. OPNsense is currently only a flat Ansible inventory host and has no repository role or pinned OPNsense collection. The official `os-netbird` plugin is available only on compatible OPNsense releases and exposes package, settings, authentication, service, and status APIs; interface assignment may require the installed release's core interface API.

Enrollment creates a durable peer identity on OPNsense and a remote peer object in NetBird. The setup key is sensitive one-use material governed by `lifecycle.secret-operations`; it must not enter OpenTofu state or the encrypted long-lived credential document.

## Goals / Non-Goals

**Goals:**
- Establish reusable Ansible ownership of OPNsense configuration.
- Prove the installed firmware, package, APIs, and recovery path before mutation.
- Install and enroll the official NetBird plugin as a healthy North York peer.
- Assign `wt0` while preserving existing LAN administration.
- Leave LAN routing and NetBird DNS inactive.
- Make a repeated run idempotent and avoid repeated enrollment.

**Non-Goals:**
- Assign the peer as a NetBird Network router.
- Enable a routed-access policy or expose the North York LAN.
- Configure Dnsmasq, NetBird nameservers, NetBird SSH, or Scarborough.
- Store or manage a setup key with OpenTofu.

## Decisions

### Reusable role with site data

Create `ansible/roles/opnsense_netbird_peer/` and a bounded enrollment playbook. Reshape inventory so North York is explicit while keeping host connection details and site values outside role tasks. Role defaults contain safe product defaults; host/site variables provide the OPNsense address, expected site key, interface description, and desired peer identity. A contract compares the operational host/address with `estate.yaml` so the two inventories cannot silently diverge.

Pin `oxlorg.opnsense` in the collection requirements. Prefer stable dedicated modules for package and firewall operations and use `oxlorg.opnsense.raw` only for official plugin/core endpoints with no dedicated module.

### Read-only compatibility gate

Before change, query firmware version, package availability, current DHCP/DNS services, API routes needed by the role, current interfaces, configuration backup availability, and local management reachability. Require an `os-netbird`-compatible release at or above the official availability boundary and stop without mutation if an endpoint or recovery path is absent. Save a complete OPNsense configuration backup in protected external storage, validate its integrity/importability without mutating the router, and retain only its sanitized identifier/hash as repository evidence.

### Bounded plugin settings

Enable the NetBird service and retain the default WireGuard port unless preflight finds a conflict. Allow the plugin to realize NetBird's runtime firewall requirements, permit LAN access/client/server routes for the later router role, and leave inbound blocking disabled so NetBird policy can govern routed sessions. Disable NetBird-managed DNS and every NetBird SSH/SFTP/port-forwarding option in this prefix. Ansible owns persistent OPNsense firewall objects; NetBird's client may realize its ephemeral forwarding state.

Assign `wt0` with no address configuration and a stable North York description. Prepare required aliases and disabled rules under a firewall savepoint where the installed API supports them. No active rule grants overlay-to-LAN access yet.

### One-use enrollment outside OpenTofu

A project-owned enrollment command authenticates to NetBird with the SOPS-delivered PAT, creates a one-use setup key with no auto-group assignment, and holds it only in a private volatile channel. Ansible posts the key and management URL through the plugin authentication API, invokes `up`, and checks the status API. The command retires the key in a finally/trap path after success or failure.

Before creating a key, the role reads local plugin status and the NetBird peer list. If the intended peer is already connected, it reconciles settings and performs no enrollment. Duplicate or ambiguous peer identity is a hard stop for operator reconciliation.

### Routing stays a separate activation

Enrollment does not add the peer to the OpenTofu-managed router group or declare `netbird_network_router`. Interface rules remain absent or disabled. The next stack member discovers the uniquely named peer, activates the persistent firewall path, and assigns the route in a separate reviewed transition.

## Enforcement design

- `tests/ansible/opnsense-static-check` installs the pinned collection in an isolated path, runs inventory parsing, role argument validation where available, and `ansible-playbook --syntax-check` with dummy credential-file paths. It compares North York host/address data with `estate.yaml`. It does not contact the router.
- `tests/ansible/opnsense-netbird-contracts.bats` checks role ownership, approved module/raw endpoint use, bounded plugin settings, no plaintext/setup-key persistence, trap-based retirement, no OPNsense Terraform provider, no Scarborough data, and no effective routing rule. It proves declared structure, not live API behavior.
- The enrollment runbook's preflight records firmware/package/API/backup and management-path observations, including physical presence or a working console fallback. Post-enrollment verifies `wt0`, service state, connected management status, unique peer identity, disabled route assignment, a bounded negative LAN probe, and a second no-change Ansible run.
- The rollback procedure disconnects NetBird, restores/removes only role-owned interface/firewall/plugin state, optionally uninstalls the package, and rechecks LAN administration. A saved OPNsense configuration is the last-resort recovery input, not the normal rollback.

## Risks / Trade-offs

- [Router automation can cause lockout] -> Require local-LAN management, backup, read-only preflight, firewall savepoints, and no route activation.
- [Plugin API differs by installed release] -> Probe exact endpoints and payload round-trips before mutation; fail closed rather than editing `config.xml`.
- [Enrollment key leaks through logs] -> Use volatile delivery, `no_log`, disabled shell tracing, and unconditional retirement.
- [A failed run creates duplicate peers] -> Check local and remote status before generating a key and stop on ambiguity.
- [Allowing NetBird runtime firewall configuration blurs ownership] -> Limit it to plugin runtime realization; Ansible remains the only owner of persistent OPNsense rules and OpenTofu owns remote policy.
- [`wt0` assignment alters interface state] -> Assign without addressing or pass rules and verify LAN access immediately.

## Migration Plan

1. Add the collection lock, site-aware inventory, reusable role, playbook, static checks, and runbook using dummy values.
2. Run static validation and confirm inventory agrees with the applied Estate prefix.
3. Follow read-only preflight, store and validate a complete protected external configuration backup, and prove local-LAN plus console recovery paths unless physically present.
4. Install `os-netbird`, set bounded plugin values, and assign `wt0` without active overlay-to-LAN rules.
5. Create one one-use setup key, enroll, verify local/remote health, and retire the key.
6. Run the playbook again and require no second key, peer, or configuration change.
7. Verify the North York Network still has no router and the LAN remains unreachable through it.
8. Exercise or review rollback, then run normal validation before route activation.
