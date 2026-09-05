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

Extend the existing credential preflight into one North York playbook. The default run is read-only. A boolean gate enables enrollment only after the operator supplies a setup key. Keep site values in play variables and use the existing inventory host; a reusable role is premature for one router.

Use `oxlorg.opnsense.raw` only for the installed plugin's official API because the pinned collection has no dedicated NetBird module. Keep HTTPS verification and `no_log` enabled.

### Preflight only what enrollment uses

Use the recorded OPNsense 26.7.3 inspection and read NetBird settings, authentication, service, and status endpoints. Require the installed official plugin and successful API responses. Do not inspect unrelated DNS/DHCP, firewall, backup, or console systems.

### Keep enrollment settings minimal

Configure the plugin with NetBird DNS and NetBird SSH capabilities disabled, authenticate using the management URL and one-use key, and bring the service up. Do not assign `wt0` or create persistent firewall objects; the later routing change owns that work.

### Keep the setup key human-controlled and ephemeral

The operator creates one no-auto-group, one-use setup key in NetBird using an authorized administrator account. A hidden shell read places it in `NETBIRD_SETUP_KEY` only for the SecretSpec-launched Ansible process. Tasks that access it use `no_log`. The operator deletes the setup key in NetBird after success or failure.

Do not add the key to SecretSpec, SOPS, OpenTofu, files, command arguments, or repository scripts. Automated key creation would require broadening the current NetBird credential and is unnecessary for one router.

### Detect prior enrollment

Read local plugin status before requesting a key. If OPNsense is already connected as the intended peer, skip authentication and reconcile only bounded settings. Stop when local and remote identities are duplicate or ambiguous.

## Risks / Trade-offs

- [Plugin API differs from expectations] -> Probe every endpoint read-only and stop before enrollment.
- [Setup key leaks] -> Use hidden environment input, `no_log`, no tracing, and manual deletion after the result.
- [Enrollment creates a duplicate peer] -> Check local status and the NetBird peer list before accepting a key.
- [Enrollment unexpectedly enables routing] -> Configure no interface or firewall state and verify the Network still has no router.

## Migration Plan

1. Implement and statically validate the read-only and gated enrollment paths.
2. Run live read-only preflight and stop if the plugin or endpoint contract differs.
3. Ask the operator to create one no-auto-group, one-use setup key.
4. Run the gated enrollment, verify one connected peer, and delete the setup key.
5. Run the playbook again without a key and require no enrollment change.
