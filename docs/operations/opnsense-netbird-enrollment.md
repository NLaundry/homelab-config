# Enroll North York OPNsense in NetBird

## Scope

Enroll the already-installed official `os-netbird` plugin as one NetBird peer.
Do not assign `wt0`, create firewall objects, assign a Network router, enable a
routed policy, distribute DNS, or change Scarborough.

## Run read-only preflight

From the repository root:

```sh
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
ansible-galaxy collection install \
  -r ansible/requirements.yml -p "$work/collections"

ANSIBLE_COLLECTIONS_PATH="$work/collections" \
  secretspec --file secretspec.toml run \
  --profile north_york --scope opnsense -- \
  ansible-playbook -i ansible/inventory.yml \
  ansible/playbooks/opnsense-netbird-enrollment.yml
```

The default playbook performs HTTP GET requests only for:

- `netbird/settings/get`
- `netbird/authentication/get`
- `netbird/service/status`
- `netbird/status/status`

Stop if any endpoint fails. The separately scoped NetBird inventory must also
show one North York Network, no assigned router, and at most one intended
OPNsense peer.

## Prepare and connect manually

Before enrollment, run the same scoped playbook once with
`-e opnsense_netbird_prepare=true`. This enables the plugin while disabling
NetBird DNS, NetBird SSH, and all client/server route acceptance. Do not use this
flag after the peer is connected.

The current NetBird automation token cannot create setup keys. In the NetBird
administrator dashboard, create one key with:

- Name: `North York OPNsense Enrollment`
- Type: one-use
- Automatic group assignment: none
- Expiry: the shortest practical interval

In OPNsense, open **VPN → NetBird → Authentication**, enter the management URL
and setup key, and select **Connect**. Do not paste the key into chat, save it in
SOPS, write it to a file, or put it in a command argument.

The official plugin retains the submitted value in its local configuration and
exposes no supported clear operation. The operator accepted this behavior because
one-use consumption and immediate deletion from NetBird make the retained value
invalid. Delete the setup key from NetBird after success or failure.

## Verify after enrollment

Require all of the following before continuing to routing activation:

- Exactly one intended OPNsense peer is connected.
- A default playbook run needs no key and makes no enrollment change.
- The North York Network still has no router or routed-access policy.
- No setup key exists in Git, SOPS, OpenTofu state, command arguments, or logs.

## Disconnect

Before routing activation, rollback is limited to the plugin:

1. Call the official NetBird authentication `down` API.
2. Disable the plugin service if required.
3. Confirm local OPNsense administration still works.
4. Delete the remote peer only after confirming it is the intended identity.

Do not change interfaces or firewall rules because this enrollment does not own
any.
