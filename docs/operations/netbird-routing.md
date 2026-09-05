# North York LAN access

## Scope

`NY-Access` contains the approved iPhone and MacBook peers and permits administrator-initiated access to `10.10.10.0/24`. OPNsense is assigned directly as the Network router with masquerading. `SC-Access` is the naming convention for later Scarborough work; this change does not create it or change Scarborough.

No DNS, NetBird SSH, manual interface assignment, or persistent firewall rules are added. The official plugin handles forwarding. If this is insufficient, stop rather than adding firewall rules silently.

## Validate and review

Use normal `tofu fmt -check`, locked initialization, `tofu validate`, and Ansible syntax checking while editing. Review one normal plan before activation. Keep state and saved plans encrypted under `${XDG_STATE_HOME:-$HOME/.local/state}/homelab-config/netbird/`, not Git. Run OpenTofu through SecretSpec scope `opentofu` and Ansible through `opnsense`; do not export resolved secrets into the parent shell.

Before activation, confirm exact peer membership, the connected OPNsense identity, and effective policies/routes. The existing default peer-to-peer policy is not the LAN access policy; do not add the LAN resource to `All`.

## Quick connection checks

Run in the Nix shell from the repository root:

```sh
secretspec --file secretspec.toml run --profile north_york --scope opentofu -- \
  bats --filter 'NetBird API connection' tests/verify/iac-connectors.bats

secretspec --file secretspec.toml run --profile north_york --scope opnsense -- \
  bats --filter 'OPNsense API connection' tests/verify/iac-connectors.bats
```

These are authenticated reads, not network changes. Each needs only its own credentials and network access. A failed API check is not interchangeable with a failed ping.

For the routed test, use the MacBook away from the North York LAN (for example, through a cellular hotspot). Confirm NetBird is connected and identify its actual tunnel interface. Select a known listening service on an approved Estate LAN address. Then set `ROUTED_TARGET`, `ROUTED_PORT`, and `NETBIRD_INTERFACE` and run:

```sh
OFF_LAN_TEST=1 bats --filter 'North York routed service connection' \
  tests/verify/iac-connectors.bats
```

Export those three non-secret values before running. The check verifies the selected route interface and opens one short-timeout TCP connection. It does not log in or write data. Alternatively, use the iPhone on cellular with Wi-Fi off and open an approved LAN service. Record that as a manual test, not a Bats result.

A LAN-local connection is not proof of NetBird routing. A skipped test is not a pass. Positive access also does not prove unauthorized denial; review effective policies and report that limit honestly. No second test-device provisioning is required.

## Accept or withdraw

After approved activation, require a successful off-LAN service connection, retained local OPNsense management, and no-change OpenTofu/Ansible reconciliation. If validation fails, disable the access policy and router assignment, then restore the changed plugin routing settings. Keep the enrolled peer and baseline Network/resource/group; do not destroy or re-enroll them.

No backup project, firewall savepoint framework, or rollback drill is required for this plugin-managed path.
