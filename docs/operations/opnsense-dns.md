# North York DNS and DHCP

## Current ownership

Dnsmasq is commissioned. Routine runs maintain DNS/DHCP settings, reservations,
shared records, lease holds, IPv4 ranges, forwarding rows and the narrow Guest
TCP/53 rule. They do not migrate ISC leases, perform the original resolver
handoff, enable a disabled service or shut down active DHCP. `cutover_dns=true`
is retired and fails.

Source: `ansible/playbooks/opnsense-dns.yml`, `ansible/roles/opnsense_dns/` and
`ansible/vars/north-york-dns.yml`. Preserve the seven original reservations, the
later CA reservation and all **nine unnamed lease holds**. An old snapshot or a
lease disappearing from an API response is not permission to retire a hold.

The [NetBird role](netbird-routing.md) owns the commissioned plugin settings,
validates the enabled/locked `opt2` (`wt0`) assignment, and owns the unchanged
inbound IPv4 any-to-any rule. DNS owns only its listeners and DHCP exclusions on
that interface. `opnsense_dns_netbird_interface: ""` removes overlay DNS listening;
retain `opnsense_dns_dhcp_excluded_interfaces: [opt2]`. That listener change must
not enable overlay DHCP or remove the general NetBird rule.

The [original change record](../../openspec/changes/configure-north-york-dns/runbook.md)
is history and incomplete acceptance, not a commissioning procedure to repeat.

## Prepare and compare

Run from the repository root with the existing operator identity:

```sh
nix develop
ansible-galaxy collection install -r ansible/requirements.yml -p .ansible/collections
export SOPS_AGE_KEY_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"

ANSIBLE_CONFIG=ansible/ansible.cfg \
  secretspec --file secretspec.toml run --profile north_york --scope opnsense -- \
  ansible-playbook -i ansible/inventory.yml ansible/playbooks/opnsense-dns.yml
```

Default runs read and compare only. `--check` also prevents writes, even with an
apply flag. Expect saved-difference reporting with `runtime_verified: false`, not
proof that clients work. Stop on incomplete inventory, collisions, denied APIs or
TLS failure; do not widen grants or disable checks.

All callers share `ansible/group_vars/all/opnsense.yml` and
`ansible/tasks/opnsense-connection.yml`. The default and scoped URL now select
`private`, verifying `opnsense.ny.laundrylab.internal` with
`certificates/laundrylab-root-ca.crt`. The explicit `legacy` recovery profile
verifies `opnsense.localdomain` with the retained certificate only when that
certificate is selected on the router. To explicitly select routine transport:

```sh
ANSIBLE_CONFIG=ansible/ansible.cfg \
  secretspec --file secretspec.toml run --profile north_york --scope opnsense -- \
  env OPNSENSE_PROFILE=private OPNSENSE_URL=https://opnsense.ny.laundrylab.internal \
  ansible-playbook -i ansible/inventory.yml ansible/playbooks/opnsense-dns.yml
```

The URL must match the selected profile's HTTPS hostname/port with no path,
query, fragment or credentials. No insecure or automatic legacy fallback exists.
Coordinate the default and encrypted URL transition through
[private HTTPS operations](opnsense-acme.md); a successful explicit-root request
alone does not complete it.

## Apply approved changes

Review exact site-data changes and the comparison first. Keep a current encrypted
router backup and independent local recovery available; avoid concurrent UI edits.
Only after approval:

```sh
ANSIBLE_CONFIG=ansible/ansible.cfg \
  secretspec --file secretspec.toml run --profile north_york --scope opnsense -- \
  ansible-playbook -i ansible/inventory.yml ansible/playbooks/opnsense-dns.yml \
  -e '{"apply_dns":true,"opnsense_dns_approved_site_data":true}'
```

Use JSON/YAML booleans for approval fields: Ansible `-e name=true` supplies a
string and deliberately fails the strict approval check. Use the same explicitly
selected transport as the approved comparison. The role
stages owned records and firewall rules before application, verifies saved
readback and deletion absence, checks Dnsmasq health, and checks selected exact
A answers from `opnsense_dns_runtime_queries`. Repeat comparison must show no
saved changes. These bounded runtime checks are **not estate acceptance**.

### Explicit removal, not omission

Removal inputs are lists of exact owned identities:

| Input | Identity prefix |
| --- | --- |
| `opnsense_dns_remove_hosts` | `homelab:north_york:host:` or `homelab:north_york:lease:` |
| `opnsense_dns_remove_ranges` | `homelab:north_york:range:` |
| `opnsense_dns_remove_domains` | `homelab:north_york:domain:` |

Each item requires `description`; optional `uuid` must match the uniquely
resolved existing row. Do not guess UUIDs. Example shape for an approved
*temporary* record, not a request to delete a production allocation:

```yaml
opnsense_dns_remove_hosts:
  - description: homelab:north_york:host:temporary-test
    # uuid: <verified existing UUID, optional>
opnsense_dns_remove_ranges: []
opnsense_dns_remove_domains: []
```

Remove the same identity from the desired list before requesting deletion;
desired/removal conflicts, duplicate or foreign identities and stale UUIDs stop
before writes. A uniquely identified already-absent row is a no-op. Omitting a
row from desired input alone preserves it; no prefix purge occurs. Keep unrelated
rows and fields intact.

To retire an alias, add `remove_aliases: [temporary.laundrylab.internal]` to its
existing desired host entry and remove it from that entry's `aliases` additions.
Old aliases plus explicit additions are preserved minus explicit removals;
removing an alias only from `aliases` does not delete it. Retain the removal intent
so a generated legacy alias is not recreated on a later run. Do not replace an
entire reservation list with a one-row example.

Reservation, hold and range deletion additionally requires
`opnsense_dns_allocation_removal_approved: true` **after operator-approved
reconciliation of current and old lease obligations**. The complete current
Dnsmasq lease inventory is checked; even a returned expired row remains protected
until reconciled. Approval cannot override a current allocation conflict. All nine
holds remain today; do not expire them by elapsed time or missing desired rows.

Keep review extra-vars files outside Git, without credentials. Compare using
`-e @/private/path/reviewed-dns.yml`, then append the same file to the approved
apply command. CLI boolean flags alone are not operator approval for deletion.

## Retry saved-but-not-applied state

A successful save can precede failed DNS/firewall activation. Treat any apply,
health, answer or readback failure as a failed run. Correct the cause, review
saved state, and explicitly retry with both flags even if no differences remain:

```sh
ANSIBLE_CONFIG=ansible/ansible.cfg \
  secretspec --file secretspec.toml run --profile north_york --scope opnsense -- \
  ansible-playbook -i ansible/inventory.yml ansible/playbooks/opnsense-dns.yml \
  -e '{"apply_dns":true,"reapply_dns":true,"opnsense_dns_approved_site_data":true}'
```

Include the same approved extra-vars and transport selection as the original run.
`reapply_dns` requires `apply_dns`; it reruns Dnsmasq reconfiguration and firewall
apply independent of saved differences. A plain no-change run is not a retry.
No automatic rollback or ISC restart is performed.

## DNS-only break-glass recovery

With explicit recovery approval, a matching served management certificate and
local console recovery ready:

```sh
ANSIBLE_CONFIG=ansible/ansible.cfg \
  secretspec --file secretspec.toml run --profile north_york --scope opnsense -- \
  ansible-playbook -i ansible/inventory.yml ansible/playbooks/opnsense-dns.yml \
  -e '{"apply_dns":true,"recover_dns":true,"opnsense_dns_approved_site_data":true,"dns_local_recovery_ready":true}'
```

Select the verified profile deliberately. Recovery connects to its fixed
`10.10.10.1` address using `curl --resolve`, retaining that profile's hostname/SNI
and trust anchor. It ignores curlrc/proxies, uses HTTP/1.1 and supplies API auth on
stdin, not argv. If the router no longer serves the selected certificate, restore
the matching GUI selection through independent management; never bypass TLS.

Recovery skips normal desired state, sets Dnsmasq's DNS port to `0`, retains its
DHCP enable state and leases, restores Unbound, and checks both services. Verify
real DNS answers and DHCP health separately. This is DNS recovery, not full lease
restoration or authorization to restart ISC. If API access is unavailable, use
local recovery. Any full DHCP-owner rollback needs a separately reviewed plan
protecting every current allocation before another DHCP server starts; do not
use a historical cutover command or blindly restore an old configuration backup.

## Acceptance remains separate

From the actual intended client, use the Nix shell's `dig` and the explicit DNS
probe (no API credentials needed):

```sh
DNS_VERIFY=1 DNS_SERVER=10.10.10.1 \
  DNS_SITE_FQDN=opnsense.ny.laundrylab.internal DNS_SITE_ADDRESS=10.10.10.1 \
  DNS_SHARED_FQDN=ca.laundrylab.internal DNS_SHARED_ADDRESS=10.10.10.12 \
  bats --filter 'DNS A answer' tests/verify/naming-trust.bats
```

This checks site/shared UDP and site TCP answers only. Missing selected context
fails; an unselected probe skips. Also verify public UDP/TCP, shared TCP, real
client renewal/dynamic naming, a disposable shared alias and protected-name
collision, normal-policy Guest ingress, IPv6 resolver withdrawal or correct
answers, WAN denial, NAS/SMB continuity and genuine off-LAN Mac/iPhone DNS.
A LAN query to the Guest address does not prove Guest ingress; LAN overlay tests,
timeouts and skips are not off-LAN passes. Keep unresolved Guest/Mac transport and
AX23 IPv6 observations open in the historical record. Do not alter firewall
policy or API grants merely to turn a failed test green.
