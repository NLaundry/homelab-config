# Operations runbooks

## North York network

### What

Prepare the North York network in five ordered steps.

### Why

Keep local recovery access while adding remote access. Do not enable LAN routing
until the control plane and router peer work independently.

### Order

1. [Confirm the inventory](north-york-inventory.md).
2. [Prepare secret custody](network-secret-operations.md).
3. [Adopt the NetBird control plane](netbird-opentofu.md).
4. [Enroll the OPNsense peer](opnsense-netbird-enrollment.md).
5. [Enable bounded LAN routing](netbird-routing.md).

The [stack](../../openspec/stacks/north-york-network-foundation/stack.yaml) records
the change order. These runbooks do not mark implementation tasks complete.

### Current limits

The inventory and operator tools exist. The SOPS policy, network credentials,
OpenTofu root, Ansible role, adapters, and network checks do not yet exist.
The later runbooks are drafts for use after those components are implemented.

Review each change before running commands. Do not paste credentials into chat,
Git, logs, or command arguments. Use dummy values for local checks.

Do not add Scarborough, application hosting, identity services, or public ingress
as part of this stack. Keep an independent local OPNsense recovery path.

## NAS storage

Use [ZFS first import and recovery](../NAS/zpool-first-import.md) when importing
the existing NAS pools or recovering from an import failure.
