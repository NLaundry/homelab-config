# North York NetBird enrollment — retired write procedure

The OPNsense peer is already commissioned. Enrollment is not a routine operation.
Use [NetBird routing](netbird-routing.md) for plugin settings, overlay rules and
explicit apply/reapply; use [OpenTofu operations](netbird-opentofu.md) for the
existing control-plane objects and lost-state recovery.

## Retained read-only diagnosis

The old playbook retains only authenticated reads of NetBird settings,
authentication, service status and peer status. Its output is suppressed because
authentication state can contain sensitive material. It does not connect,
disconnect, disable, prepare or reset a peer. `opnsense_netbird_prepare=true` is
retired and fails, even if the peer appears offline.

From the repository root:

```sh
nix develop
ansible-galaxy collection install -r ansible/requirements.yml -p .ansible/collections
export SOPS_AGE_KEY_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"
ANSIBLE_CONFIG=ansible/ansible.cfg \
  secretspec --file secretspec.toml run --profile north_york --scope opnsense -- \
  ansible-playbook -i ansible/inventory.yml \
  ansible/playbooks/opnsense-netbird-enrollment.yml
```

Use the [shared verified transport](network-secret-operations.md#management-transport).
The default and scoped URL now use the verified private hostname. Legacy recovery
requires explicit selection and the matching served certificate; never fall back
after a TLS failure. Stop on
a denied or failed read without broadening privileges. A successful inspection
is not connectivity, routing or estate acceptance.

## Recover without replacing identity

1. Keep local OPNsense management available. Inspect the current service and the
   selected peer identity, then compare routine routing configuration.
2. For saved-but-not-synced settings, use the approved routing reapply procedure.
   Being offline does not authorize enrollment preparation.
3. If actual peer identity loss requires enrollment recovery, stop for a separately
   approved recovery plan with encrypted router backup and verified remote IDs.
   Do not call authentication `down`, delete the peer, replace a setup key or reset
   settings as a diagnostic shortcut.

The original one-use setup key was entered through the native UI; the plugin can
retain the submitted value in its private configuration. Such a value must remain
outside Git, SOPS network credentials, OpenTofu state, logs and command arguments.
The scoped Network Admin token does not authorize setup-key creation or peer
mutation. This retired guide grants no new enrollment or permission change.
