# North York NetBird control plane

## Current ownership

The existing root at `infra/netbird` owns seven resources:

| Address | Existing object | Import identifier |
| --- | --- | --- |
| `netbird_network.north_york` | North York | Network ID |
| `netbird_group.north_york_lan_resources` | North York LAN Resources, peer-free | Group ID |
| `netbird_network_resource.north_york_lan` | North York LAN, `10.10.10.0/24` | `NETWORK_ID/RESOURCE_ID` |
| `netbird_group.ny_access` | NY-Access, selected Mac/iPhone peers | Group ID |
| `netbird_network_router.north_york` | Existing OPNsense peer assignment | `NETWORK_ID/ROUTER_ID` |
| `netbird_policy.ny_access` | NY-Access to North York LAN | Policy ID |
| `netbird_nameserver_group.north_york` | North York private DNS | Nameserver-group ID |

The OPNsense peer is a read-only data source, not an imported managed peer. Do
not import unrelated objects, setup keys, the broad Default policy or Scarborough.
Ansible owns appliance settings; OpenTofu does not enroll or reset the peer.

A temporarily offline router does not itself block an ordinary plan. Its ID/name
must still match, and API failures still fail. Initial activation and live routing
acceptance require connectivity; a successful plan does not prove routed access.

## Prepare external encrypted state

Run from the repository root:

```sh
nix develop
export SOPS_AGE_KEY_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"
state_root="${XDG_STATE_HOME:-$HOME/.local/state}/homelab-config/netbird"
install -d -m 700 "$state_root" "$state_root/data"
export TF_DATA_DIR="$state_root/data"
```

Use the existing identity and backend. Do not initialize over missing state until
it is clear whether recovery or fresh state is intended. For an approved backend
initialization or reconnection:

```sh
secretspec run --profile north_york --scope opentofu -- \
  tofu -chdir=infra/netbird init -input=false -lockfile=readonly \
  -backend-config="path=$state_root/terraform.tfstate"
```

State, working data and saved plans remain outside Git. Keep native encryption
enforced and the provider lock unchanged unless an upgrade is explicitly intended.
Do not export resolved credentials into the parent shell or enable command tracing.

## Review and apply

```sh
secretspec run --profile north_york --scope opentofu -- \
  tofu -chdir=infra/netbird plan -input=false -out="$state_root/reviewed.tfplan"
```

Review changes against all seven owned resources. Expected routing and DNS objects
are no longer forbidden baseline additions. Still stop on unexpected deletion,
replacement, wider membership, changed peer identity, reverse initiation or any
unowned-object change. Keep state locking enabled.

Only after explicit approval, apply that exact encrypted plan:

```sh
secretspec run --profile north_york --scope opentofu -- \
  tofu -chdir=infra/netbird apply -input=false "$state_root/reviewed.tfplan"
rm -f "$state_root/reviewed.tfplan"
```

Run a new normal plan and require no changes. Verify off-LAN DNS and routed access
separately. DNS distribution to NY-Access is not a traffic-denial policy; retain
the documented broad Default-policy and appliance-boundary distinction.

## Recover lost state without deleting remote objects

1. Preserve any surviving encrypted state/backups and stop other writers. Prefer
   restoring a verified independent encrypted state copy to re-importing objects.
2. If state truly cannot be restored, initialize a separate protected recovery
   state location and inspect live object names, IDs, relationships and uniqueness
   through the native UI/API. Record only public identities. Do not assume that
   name equality alone proves ownership.
3. Re-import **all seven** existing resources from the table. Each import uses the
   existing ID confirmed in step 2; the router import ID is not the peer ID.
4. Review a normal plan. Do not apply unexpected creations as a substitute for
   missing imports. Accept recovered ownership only after a no-change plan, or
   after explicitly reviewing legitimate drift separately.
5. Retain independent encrypted state custody and verify live access separately.

Example for the router assignment, after setting verified public IDs:

```sh
secretspec run --profile north_york --scope opentofu -- \
  tofu -chdir=infra/netbird import netbird_network_router.north_york \
  "$NETWORK_ID/$ROUTER_ID"
```

Use the other exact addresses and identifier forms in the table. Imports affect
local managed state, not remote resources. Never run `destroy` for state recovery.
For a wrong state binding, review `tofu state rm` and re-import the correct object;
do not delete the live object. The three-object baseline adoption procedure is
historical, not sufficient recovery for the current root.
