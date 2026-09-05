## Context

North York OPNsense 26.7.3 already has the official `os-netbird` plugin. The repository already has pinned `oxlorg.opnsense`, authenticated SecretSpec delivery, and a trusted OPNsense TLS certificate. The North York NetBird Network exists with no router or policy.

The current NetBird automation token cannot create setup keys. A human administrator must create the one-use key at the enrollment checkpoint.

## Goals / Non-Goals

**Goals:**
- Confirm the installed plugin and required API endpoints before mutation.
- Enroll OPNsense as one uniquely named NetBird peer.
- Disable NetBird-managed DNS and NetBird SSH features.
- Avoid duplicate enrollment and persistent setup-key material.

**Non-Goals:**
- Package installation, reusable multi-site roles, or inventory restructuring.
- `wt0` assignment, firewall aliases/rules, Network router assignment, access policy, or LAN reachability.
- OPNsense backup automation or rollback drills before this bounded plugin-only mutation.

## Decisions

### Use one bounded playbook

Extend the existing credential preflight into one North York playbook. The default run is read-only. A boolean gate prepares bounded settings before the operator completes enrollment in the official OPNsense UI. Keep site values in play variables and use the existing inventory host; a reusable role is premature for one router.

Use `oxlorg.opnsense.raw` only for the installed plugin's official API because the pinned collection has no dedicated NetBird module. Keep HTTPS verification and `no_log` enabled.

### Preflight only what enrollment uses

Use the recorded OPNsense 26.7.3 inspection and read NetBird settings, authentication, service, and status endpoints. Require the installed official plugin and successful API responses. Do not inspect unrelated DNS/DHCP, firewall, backup, or console systems.

### Keep enrollment settings minimal

Configure the plugin with NetBird DNS, NetBird SSH capabilities, and all route acceptance disabled. The operator then authenticates using the management URL and one-use key through the official OPNsense UI. Do not assign `wt0` or create persistent firewall objects; the later routing change owns that work.

### Keep the setup key human-controlled and ephemeral

The operator creates one no-auto-group, one-use setup key in NetBird using an authorized administrator account. The operator enters the key only in the official OPNsense Authentication form and deletes it from NetBird after success or failure.

The official plugin persists the submitted value in its local configuration model and exposes no supported clear operation. The operator accepts this limitation because one-use consumption and remote deletion make the retained value invalid. Do not add the key to SecretSpec, SOPS, OpenTofu, repository files, command arguments, logs, or scripts. Automated key creation would require broadening the current NetBird credential and is unnecessary for one router.

### Detect prior enrollment

Read local plugin status before requesting a key. If OPNsense is already connected as the intended peer, do not request another key or rerun settings preparation. Stop when local and remote identities are duplicate or ambiguous.

## Risks / Trade-offs

- [Plugin API differs from expectations] -> Probe every endpoint read-only and stop before enrollment.
- [Setup key leaks] -> Use hidden environment input, `no_log`, no tracing, and manual deletion after the result.
- [Enrollment creates a duplicate peer] -> Check local status and the NetBird peer list before accepting a key.
- [Enrollment unexpectedly enables routing] -> Configure no interface or firewall state and verify the Network still has no router.

## Migration Plan

1. Implement and statically validate the read-only preflight and gated settings preparation.
2. Run live read-only preflight and stop if the plugin or endpoint contract differs.
3. Ask the operator to create one no-auto-group, one-use setup key.
4. Connect through the official OPNsense UI, verify one connected peer, and delete the setup key.
5. Run the playbook again without a key and require no enrollment change.
