# Network secret operations

Use [the operator runbook](../../../docs/operations/network-secret-operations.md).
It covers what to prepare, why it matters, secret custody, permissions, checks,
rotation, and recovery.

The root `.sops.yaml`, custody preparation, and OPNsense ACL discovery are recorded
as complete. SecretSpec 0.20.0 packaging, root `secretspec.toml`, and one-time dummy
delivery verification are also complete. The shared secret foundation is complete. Local OpenTofu credential/encryption
wiring, Ansible credential delivery, encrypted `secrets/network.yaml`, and bounded
read-only authentication are recorded as passing. Full NetBird resources and
OPNsense enrollment remain later changes; this runbook does not authorize them.
