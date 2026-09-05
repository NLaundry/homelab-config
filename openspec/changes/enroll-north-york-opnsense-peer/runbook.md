# User runbook: enroll North York OPNsense

## Why you are needed

This proposal changes the production gateway. You must confirm a recovery path, validate the observed router state, and approve the point where the plugin is installed and enrolled.

## Prerequisites

- Be physically at North York or have a tested local-LAN administration path and console recovery option.
- Complete the network secret proposal, including the restricted OPNsense API credential.
- Complete the unrouted NetBird baseline proposal.
- Do not rely on the NetBird path being created by this change as the recovery path for this change.

## When to act

### Tasks 2.2–2.4: confirm preflight and recovery

Review the read-only preflight output and confirm:

- installed OPNsense version
- official `os-netbird` availability
- required package, NetBird plugin, interface, firewall, service, status, and backup APIs
- current DNS/DHCP services are observed but will not be changed
- local OPNsense GUI/SSH/console access works
- a complete pre-change configuration backup exists in protected external storage and passes the documented non-mutating integrity/importability check; only its sanitized identifier/hash enters repository evidence

Stop before mutation if any required API is absent or if automation proposes direct `config.xml` editing.

### Tasks 3.1–3.4: approve plugin and interface changes

Approve the Ansible diff only if it is limited to:

- official `os-netbird` installation
- bounded plugin settings
- `wt0` assignment without addressing
- role-owned aliases and disabled firewall preparation

Confirm NetBird DNS and all NetBird SSH/SFTP/forwarding features remain disabled. Keep the local management session open while changes run and report loss of access immediately.

### Tasks 4.2–4.4: authorize one-use enrollment

Allow the guarded enrollment command to create one setup key, consume it immediately, and retire it in unconditional cleanup. Do not copy, inspect, or save the key. Afterward, inspect the NetBird dashboard and OPNsense status and confirm the key is no longer valid and:

- exactly one intended OPNsense peer exists
- the peer is connected
- `wt0` is assigned
- the North York Network still has no routing peer
- bounded probes from the NetBird administrator peer confirm selected LAN targets remain unreachable

If duplicate peers appear, stop and reconcile them before continuing.

### Task 4.5: confirm idempotence

Review the second playbook result. It must not create another key, peer, interface, package action, or managed-setting change.

### Task 5.4: choose rollback evidence depth

Prefer a non-destructive review or disconnect/reconnect drill while physically local. If full uninstall is exercised, verify local management after every step and restore the intended enrolled prefix before moving to routing activation.

## Stop conditions

Stop immediately on:

- lost or unstable local router management
- unsupported firmware/plugin/API behavior
- a setup key in output, files, SOPS, or state
- duplicate or ambiguous peers
- an enabled overlay-to-LAN firewall rule
- a NetBird Network router assignment
- any DNS/DHCP or Scarborough change

## Evidence to record

Record firmware/package versions, API availability, backup identifier/hash, play recap, peer ID/name/status, interface name, and redacted rule identifiers. Never record API credentials, setup keys, private configuration exports, or complete environment output.
