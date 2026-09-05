# Adopt the North York NetBird Network

## Scope

OpenTofu manages only:

- Network `North York`.
- Peer-free resource group `North York LAN Resources`.
- LAN resource `North York LAN` at the `estate.yaml` boundary `10.10.10.0/24`.

This procedure does not manage peers, router groups, routers, policies, DNS,
setup keys, OPNsense, or Scarborough. Stop if a plan includes any of them.

## Prepare external state

Run commands from the repository root. State, working data, and the encrypted
saved plan stay outside Git.

```sh
state_root="${XDG_STATE_HOME:-$HOME/.local/state}/homelab-config/netbird"
install -d -m 700 "$state_root" "$state_root/data"
export TF_DATA_DIR="$state_root/data"

secretspec --file secretspec.toml run --profile north_york --scope opentofu -- \
  tofu -chdir=infra/netbird init -input=false -lockfile=readonly \
  -backend-config="path=$state_root/terraform.tfstate"
```

Do not export resolved SecretSpec values into the parent shell or enable command
tracing.

## Inspect before import

Use read-only NetBird inspection to identify exact IDs for the three named
objects and confirm:

- There is at most one exact name match for each object.
- The LAN address is `10.10.10.0/24`.
- The resource group has no peers.
- The Network has no router and no effective routed-LAN policy.

Stop on duplicate ownership, a different address, an existing router, or active
routed access. Ignore and do not import unrelated account objects.

## Import exact matches

Import only objects proven to exist. Omit the corresponding command for an
object proven absent.

```sh
secretspec --file secretspec.toml run --profile north_york --scope opentofu -- \
  tofu -chdir=infra/netbird import netbird_network.north_york NETWORK_ID

secretspec --file secretspec.toml run --profile north_york --scope opentofu -- \
  tofu -chdir=infra/netbird import \
  netbird_group.north_york_lan_resources RESOURCE_GROUP_ID

secretspec --file secretspec.toml run --profile north_york --scope opentofu -- \
  tofu -chdir=infra/netbird import \
  netbird_network_resource.north_york_lan NETWORK_ID/RESOURCE_ID
```

Imports change only external OpenTofu state; they do not change NetBird.

## Plan and apply

```sh
secretspec --file secretspec.toml run --profile north_york --scope opentofu -- \
  tofu -chdir=infra/netbird plan -input=false -lock=false \
  -out="$state_root/baseline.tfplan"
```

Accept only creation of a proven-missing named baseline object or harmless
metadata normalization. Stop on deletion, replacement, routing, policy, peer,
DNS, setup-key, or unrelated-account changes.

Apply the exact reviewed encrypted plan:

```sh
secretspec --file secretspec.toml run --profile north_york --scope opentofu -- \
  tofu -chdir=infra/netbird apply -input=false "$state_root/baseline.tfplan"
rm -f "$state_root/baseline.tfplan"
```

Run a new normal plan. Success is `0 to add, 0 to change, 0 to destroy`.

## Recover lost state

Do not run `destroy`. If external state is lost:

1. Recreate the external directories and initialize the backend.
2. Repeat read-only inspection.
3. Re-import the same three live object IDs.
4. Accept the recovered state only after a no-change plan.

If an object was imported at the wrong address, review and use `tofu state rm`;
do not delete the remote object.
