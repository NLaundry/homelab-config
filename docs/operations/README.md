# Operations runbooks

## North York network

The network stack is running. OpenTofu manages the selected NetBird objects;
Ansible manages OPNsense through scoped credentials and verified HTTPS.
Commissioning is not a routine reconciliation step.

1. [Inventory](north-york-inventory.md) — recorded identities and addresses.
2. [Secret custody](network-secret-operations.md) — scoped delivery and recovery.
3. [NetBird control plane](netbird-opentofu.md) — routine plans and complete-root recovery.
4. [NetBird peer inspection](opnsense-netbird-enrollment.md) — retired enrollment writes and recovery boundary.
5. [NetBird forwarding](netbird-routing.md) — approved overlay rule and explicit apply/reapply.
6. [DNS and DHCP](opnsense-dns.md) — managed records, explicit removal and DNS-only recovery.

The [foundation stack](../../openspec/stacks/north-york-network-foundation/stack.yaml)
records the original order. Do not add Scarborough or public ingress as part of
routine reconciliation. Keep independent local OPNsense recovery access.

## North York naming and private trust

1. [Root custody](private-root-authority.md) — initialize once; routine operation keeps root locked.
2. [NAS networking](nas-networking.md) — persistent NetworkManager profiles, bridge and resolver recovery.
3. [CA operation](step-ca.md) — existing intermediate, declared public policy and controlled migration.
4. [Native router ACME](opnsense-acme.md) — Ansible adoption, exact permissions and manual WebGUI boundary.
5. [Backups and recovery](north-york-backups.md) — consistent independent encrypted copies and restore safeguards.
6. [Service VM storage](service-vm-storage.md) — dataset/image ownership and startup boundaries.

The [naming/trust stack](../../openspec/stacks/north-york-naming-trust/notes.md)
records current ownership and pending acceptance. Initial issuance and read-only
private HTTPS/API checks passed; they do not prove real renewal, normal-browser
trust on every client, genuine off-LAN operation or current isolated recovery.
The CA public-configuration candidate is not activated by a successful build.

## Checks and changes

Use `make check` for evaluation.
Use the [repository command guide](../../README.md) for build and activation.
Live activation, backup service stops, issuance, reloads and state-changing probes
need explicit authorization. A saved configuration or skipped check is not an
accepted live outcome. Never put credentials in Git, chat, logs or arguments.

## NAS storage

Use [ZFS first import and recovery](../NAS/zpool-first-import.md) for existing pool
imports. A local snapshot is not an independent backup. Preserve the current
service image path when selecting an older configuration for rollback.
