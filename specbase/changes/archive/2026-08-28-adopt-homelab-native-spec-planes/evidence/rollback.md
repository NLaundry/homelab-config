# Rollback

The plane migration is one repository consistency boundary. After delivery, rollback is one Git revert of the migration commit. The revert restores:

- the previous `specbase/config.yaml` roster,
- the previous `specbase/specs/` tree,
- generated Pi skills/prompts and review routing,
- enforcement manifests, conformance sources, and evidence metadata introduced here,
- Nix/test registry and Make harness changes.

No running-host rollback is required:

- no NixOS generation was activated,
- the persistent deployment and reboot procedures were explicitly deferred,
- the NAS closure and VM derivations were built without activation,
- read-only SSH/Estate/deployment-health probes changed no host state,
- live SMB fixtures used unique namespaces and completed cleanup successfully.

If rollback occurs while an independent later deployment has happened, do not roll back that host merely because repository governance is reverted; evaluate that deployment under its own Lifecycle evidence.
