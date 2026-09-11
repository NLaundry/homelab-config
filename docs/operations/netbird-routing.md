# North York LAN access

## Scope

`NY-Access` contains the approved iPhone and MacBook peers and permits administrator-initiated access to `10.10.10.0/24`. OPNsense is assigned directly as the Network router with masquerading. `SC-Access` is the naming convention for later Scarborough work; this change does not create it or change Scarborough.

The original routing activation added no DNS, manual interface assignment or persistent firewall rule. The subsequent operator-approved private-DNS rollout follows the [official OPNsense guide](https://docs.netbird.io/get-started/install/opnsense): `wt0` is assigned as NetBird (`opt2`), enabled and locked with both IP types None. Ansible's `opnsense_netbird` role validates the enabled/locked assignment and owns the unchanged inbound IPv4 any-to-any rule. The separate `opnsense_dns` role owns DNS listening and DHCP exclusions. Removing its overlay listener leaves the DHCP exclusion and general NetBird rule intact. NetBird ACLs are the overlay access boundary; the currently enabled Default All↔All policy is broad. Guest and WAN ingress rules remain intact. No NetBird SSH or NAT troubleshooting changes are included.

The non-primary `laundrylab.internal` nameserver group is distributed only to `NY-Access`, excluding OPNsense. This covers site names and `ca.laundrylab.internal` without taking over public DNS. Use [current DNS operations](opnsense-dns.md); the [overlay rollout record](../../openspec/changes/distribute-north-york-netbird-dns/runbook.md) is history. DNS distribution groups are not access isolation. The existing rollout does not establish acceptance of this refactor or the outstanding off-LAN Mac/iPhone sweep.

## Validate and review

Use normal `tofu fmt -check`, locked initialization, `tofu validate`, and Ansible syntax checking while editing. Review one normal plan before activation. Keep state and saved plans encrypted under `${XDG_STATE_HOME:-$HOME/.local/state}/homelab-config/netbird/`, not Git. Run OpenTofu through SecretSpec scope `opentofu` and Ansible through `opnsense`; do not export resolved secrets into the parent shell.

Before activation, confirm exact peer membership, the connected OPNsense identity, and effective policies/routes. Ordinary OpenTofu planning retains the selected peer ID/name check but does not require it to be online; API failure or the wrong identity still fails. An offline peer is not a routing pass. The existing default peer-to-peer policy is not the LAN access policy; do not add the LAN resource to `All`. Use [OpenTofu operations](netbird-opentofu.md) for encrypted state, reviewed plans and full-root recovery.

## Compare and apply appliance settings

Run from the repository root:

```sh
nix develop
ansible-galaxy collection install -r ansible/requirements.yml -p .ansible/collections
export SOPS_AGE_KEY_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"

ANSIBLE_CONFIG=ansible/ansible.cfg \
  secretspec --file secretspec.toml run --profile north_york --scope opnsense -- \
  ansible-playbook -i ansible/inventory.yml \
  ansible/playbooks/opnsense-netbird-routing.yml
```

Default is read/compare only. The role requires an enabled commissioned plugin;
it never imports enrollment preparation. It keeps LAN access and server-route
acceptance enabled, client-route acceptance off, and NetBird DNS/SSH disabled.
The existing `wt0` assignment remains enabled/locked with IPv4/IPv6 None; do not
reassign it during reconciliation.

This installed assignment API omits the enabled flag. The approved compatibility
check reads the latest saved configuration through `core/backup/download/this`
only when that field is absent, then verifies the selected interface's identity,
enablement and lock against the assignment response. It keeps private XML in
memory only and suppresses it from logs. Missing, conflicting, malformed or
disabled state fails before writes; there is no assumed-enabled default.

That fallback requires **Diagnostics: Configuration History**
(`page-diagnostics-configurationhistory`), already explicitly granted. It also
permits backup deletion/restore, although this role uses GET only. This is a
conditional routing prerequisite, not an ACME privilege. Stop concurrent UI edits;
saved configuration flags do not prove runtime forwarding.

All OPNsense callers share the [verified transport](network-secret-operations.md#management-transport).
The default and scoped URL now select verified private-name transport. To select
that same profile explicitly, set only the non-secret child environment values:

```sh
ANSIBLE_CONFIG=ansible/ansible.cfg \
  secretspec --file secretspec.toml run --profile north_york --scope opnsense -- \
  env OPNSENSE_PROFILE=private OPNSENSE_URL=https://opnsense.ny.laundrylab.internal \
  ansible-playbook -i ansible/inventory.yml \
  ansible/playbooks/opnsense-netbird-routing.yml
```

Use the same selected profile
for approved apply/reapply. A name, trust or authorization failure ends the run;
never fall back insecurely or widen grants.

After reviewing comparison, obtaining explicit approval and retaining an encrypted
router backup/local recovery, apply:

```sh
ANSIBLE_CONFIG=ansible/ansible.cfg \
  secretspec --file secretspec.toml run --profile north_york --scope opnsense -- \
  ansible-playbook -i ansible/inventory.yml \
  ansible/playbooks/opnsense-netbird-routing.yml -e apply_routing=true
```

The role saves owned settings, stages its general firewall rule before applying,
syncs changed plugin settings, applies changed firewall state and checks saved
readback, service health and management connectivity. `--check` prevents writes.
A no-change comparison establishes saved equality, not runtime or routed access.

If save succeeds but sync/firewall/runtime verification fails, correct the cause
and explicitly retry, even when saved values already match:

```sh
ANSIBLE_CONFIG=ansible/ansible.cfg \
  secretspec --file secretspec.toml run --profile north_york --scope opnsense -- \
  ansible-playbook -i ansible/inventory.yml \
  ansible/playbooks/opnsense-netbird-routing.yml \
  -e apply_routing=true -e reapply_routing=true
```

`reapply_routing` requires `apply_routing`; it repeats sync and firewall apply
independent of differences. A failure remains failed; there is no automatic retry
or enrollment reset. Successful selected runtime checks are not estate acceptance.

## Quick connection checks

In the prepared Nix shell, authenticated reads are:

```sh
secretspec --file secretspec.toml run --profile north_york --scope opentofu -- \
  bats --filter 'NetBird API connection' tests/verify/iac-connectors.bats

ANSIBLE_CONFIG=ansible/ansible.cfg OPNSENSE_VERIFY=1 \
  secretspec --file secretspec.toml run --profile north_york --scope opnsense -- \
  bats --filter 'OPNsense API connection' tests/verify/iac-connectors.bats
```

These are authenticated reads, not network changes. Each needs only its own credentials and network access. The OPNsense probe reuses the shared credential preflight with explicit inventory and also requires the plugin's management connection. A failed result can therefore mean transport, authentication or disconnected-peer failure, not just failed ping. `OPNSENSE_VERIFY=1` makes missing selected context fail rather than skip.

For the routed test, use the MacBook away from the North York LAN (for example, through a cellular hotspot). Confirm NetBird is connected and identify its actual tunnel interface. Select a known listening service on an approved Estate LAN address. Then set `ROUTED_TARGET`, `ROUTED_PORT`, and `NETBIRD_INTERFACE` and run:

```sh
OFF_LAN_TEST=1 bats --filter 'North York routed service connection' \
  tests/verify/iac-connectors.bats
```

Export those three non-secret values before running. The check verifies the selected route interface and opens one short-timeout TCP connection. It does not log in or write data. Alternatively, use the iPhone on cellular with Wi-Fi off and open an approved LAN service. Record that as a manual test, not a Bats result.

A LAN-local connection is not proof of NetBird routing. A skipped test is not a pass. Positive access also does not prove unauthorized denial; review effective policies and report that limit honestly. No second test-device provisioning is required.

## Accept or withdraw

After approved activation, require a successful off-LAN service connection, retained local OPNsense management, and no-change OpenTofu/Ansible reconciliation. If validation fails, stop acceptance. With explicit withdrawal approval, review a plan disabling the access policy and router assignment, then restore the reviewed plugin forwarding settings (`routing_enabled=false` with `apply_routing=true` for the bounded plugin withdrawal). This does not delete the separately owned general overlay rule or narrow the broad Default policy. Keep the enrolled peer, Network/resource/group and encrypted state; do not destroy or re-enroll them. DNS distribution/listener withdrawal is a separate reviewed DNS change, with DHCP exclusion retained.

Retain current encrypted router backups and independent local management. Do not run a destructive production rollback drill merely to demonstrate this refactor.
