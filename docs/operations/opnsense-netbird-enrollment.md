# Enroll the OPNsense NetBird peer

## What

Install and enroll NetBird on North York OPNsense. Keep it connected but do not
assign it as a LAN router yet.

## Why

Prove the peer, local management, and recovery paths before enabling remote LAN
access. A repeated run must reuse the peer, not create another identity or key.

## Before you start

**Draft: the role, enrollment command, and playbook do not exist yet.** Complete
the [unrouted baseline](netbird-opentofu.md) and secret custody first.

Implementation must provide the pinned `oxlorg.opnsense` collection, the
`ansible/roles/opnsense_netbird_peer/` role, a bounded playbook, and a guarded
one-use enrollment command. Review their real commands before use.

You need working local OPNsense administration at `10.10.10.1` and a tested console
or equivalent recovery path independent of NetBird. Being physically nearby is
not enough if you cannot log in and recover the router.

## 1. Run read-only preflight

Confirm:

- The installed OPNsense release supports the official `os-netbird` plugin.
- The plugin package is available and the role's documented APIs match this release.
- Required package, settings, service, status, interface, firewall, backup, and
  reload operations fit the restricted automation user's privileges.
- Existing interfaces, DNS/DHCP services, management access, and port use are known.
- Ansible's OPNsense address agrees with `estate.yaml`.

Do not guess an API endpoint or edit `config.xml` directly. If required endpoints
cannot be confirmed before installation, stop. This is an unresolved compatibility
gate. A separate install stage needs an approved design/spec change first; this
runbook does not authorize that workaround.

## 2. Save a recovery copy

### 2.1 Export the configuration

Export a complete OPNsense configuration backup into protected external storage.
It may contain secrets: do not put it in Git, logs, or chat.

### 2.2 Verify the recovery copy and restore path

Check its integrity and supported import format without restoring it. Confirm
how to restore it through the independent local path. Record only its identifier
and hash. Do not proceed without a usable recovery copy.

## 3. Prepare the plugin and interface

### 3.1 Review the change and recovery protection

Review the Ansible change before applying it. Use supported savepoint protection
for firewall changes. If a required safety mechanism is unavailable, stop and
resolve the recovery procedure first.

### 3.2 Configure the plugin and interface

Configure the planned settings:

| Setting | Intended state |
|---|---|
| NetBird service | Enabled |
| WireGuard port | Default, unless preflight identifies a conflict |
| NetBird runtime firewall, LAN access, and client/server routes | Allowed for the later router role |
| NetBird client's inbound-block option | Disabled; access remains policy-controlled |
| NetBird DNS management | Disabled |
| NetBird SSH, root SSH, SFTP, and SSH forwarding | Disabled |
| `wt0` | Assigned with no address configuration |
| Persistent overlay-to-LAN pass rules | Absent or disabled |

Do not disable the OPNsense firewall. Ansible owns persistent rules; the NetBird
client may create its own runtime state. Leave existing DNS and DHCP unchanged.
Check local management after each stage. Stop if it degrades.

## 4. Enroll once

### 4.1 Check for an existing peer

1. Read local plugin status and the remote NetBird peer list before creating a key.
2. If the intended peer is already connected, reuse it and reconcile settings.
3. Stop on a duplicate, disconnected ambiguity, or unexpected identity.

### 4.2 Enroll only if needed

1. Otherwise, use the guarded enrollment operation to create one single-use key
   with no automatic group assignment.
2. Deliver it through a private volatile channel to the plugin authentication and
   `up` calls. Disable tracing and secret logging.

### 4.3 Retire and verify the key

1. Retire the key after success, failure, or interruption. Confirm retirement in
   the control plane; consuming a key is not a substitute for this check.

Do not put the key in SOPS, OpenTofu state, command arguments, or logs. If the
operation fails before retirement, revoke the key through the recovery path before
retrying. Do not blindly generate another peer.

## 5. Check the unrouted peer

### 5.1 Verify health and the unrouted boundary

Confirm the healthy service, connected management status, intended unique peer,
and assigned `wt0`. Confirm that:

- The setup key is no longer usable.
- The North York router group remains empty and has no Network router assignment.
- No active persistent rule grants overlay-to-LAN access.
- A bounded remote administrator probe cannot reach the North York LAN through
  this new path. Confirm the probing peer is connected before trusting a timeout.
- Local management, ordinary LAN traffic, and DNS/DHCP still work.

### 5.2 Confirm a repeat run makes no changes

Run the same playbook again. It must create no key or peer and make no managed
configuration changes. Investigate any repeated enrollment or drift.

## Stop or recover

Stop on management loss, unexpected routing, key exposure, duplicate peers,
unsupported APIs, or unrelated changes.

Revert the savepoint when needed. Disconnect NetBird and restore or remove only
the role-owned interface, firewall, and plugin state. Remove only a peer proven
newly created by this attempt. Preserve unrelated configuration and recheck local
administration. Use the full configuration backup only as a last resort.

Record versions, non-secret peer identifiers, backup identifiers, and results.
Never record the configuration export, setup key, or API secret.

## Source

[Planned change](../../openspec/changes/enroll-north-york-opnsense-peer/).
