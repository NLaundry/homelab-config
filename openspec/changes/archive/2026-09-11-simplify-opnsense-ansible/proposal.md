## Why

The current OPNsense Ansible implementation has grown into a migration, recovery, and acceptance framework. That makes a small router configuration difficult to understand and leaves the actual bootstrap gap: routine roles reconcile pre-existing objects, while the enrollment and first-cutover work is not implemented. This change makes Ansible responsible for configuration and leaves observable behavior to the repository's live verification probes.

## What Changes

- Keep native OPNsense ACME management, including the internal step-ca directory, certificate definition, WebGUI reload action, and renewal schedule.
- Add an explicit ACME bootstrap path that can create and register the account and create the validation, action, and certificate objects where the OPNsense API and collection support it.
- Add an explicit Dnsmasq bootstrap path for the initial resolver/DHCP transition, while retaining a small routine path for settings, reservations, ranges, and domain overrides.
- Make NetBird peer enrollment an explicit bootstrap concern, using the installed plugin API and a setup-key secret if a stable endpoint exists; otherwise document the one-time manual prerequisite.
- Reduce routine roles to desired-state writes and API response handling; use standard Ansible check mode for previews.
- Remove custom full-state reconciliation, historical lease migration logic, DNS outage recovery, XML parsing, runtime `dig` checks, and custom reapply state machines from routine Ansible.
- Keep acceptance in the existing `tests/verify` structure: `dns.bats` for core DNS, `pki.bats` for router/CA certificates, `control-plane.bats` for API connectivity, and a small routing probe only where off-LAN test inputs are available.
- Keep the ACME, Dnsmasq, and NetBird responsibilities in separate playbooks and roles.
- Correct stale Ansible documentation and test commands.

## Capabilities

### New Capabilities

- `configuration/opnsense-dns`: Declarative OPNsense Dnsmasq and DHCP bootstrap and routine configuration.
- `configuration/opnsense-acme`: Declarative OPNsense ACME configuration using the repository's internal CA.
- `configuration/opnsense-netbird`: Declarative OPNsense NetBird enrollment and routing configuration.

### Modified Capabilities

None. The branch currently has no active main capability specifications; these capabilities establish the replacement contracts.

## Impact

- Reworks `infra/ansible/playbooks/`, `infra/ansible/roles/opnsense_dns/`, `infra/ansible/roles/opnsense_acme/`, and `infra/ansible/roles/opnsense_netbird/`.
- Changes the OPNsense API operations used for first-time ACME, Dnsmasq, and NetBird setup.
- Updates the existing live probes under `tests/verify/`; no separate DHCP suite is added without a real client path. A focused routing probe may be added for off-LAN NetBird behavior.
- Keeps `infra/terraform/netbird/` as the owner of NetBird control-plane resources.
- Requires separate handling for initial certificate trust and any setup key; routine credentials remain delivered through SecretSpec.
