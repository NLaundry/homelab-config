# Adopt the NetBird control plane

## What

Put the existing North York Network, its LAN resource, and an empty router group
under OpenTofu control. Do not enable LAN routing.

## Why

Import existing objects before managing them. This preserves their identity and
avoids replacing a working network while establishing reproducible configuration.

## Before you start

**Draft: the OpenTofu root and secret adapter do not exist yet.** Complete
[secret custody](network-secret-operations.md) first. Confirm read-only API access.

Implementation must provide:

- `infra/netbird/` and its `modules/site-network/` module.
- An exact official NetBird provider version and platform lock entries.
- A reviewed secret adapter and native state and plan encryption.
- External state at `${XDG_STATE_HOME:-$HOME/.local/state}/homelab-config/netbird/terraform.tfstate`.
- `TF_DATA_DIR` and encrypted backups outside the repository.

Do not run bare OpenTofu commands with guessed import addresses or default local
state paths. The implementation must supply the final adapter and import commands.

## 1. Inspect before importing

### 1.1 Record existing objects and ownership

Use the NetBird dashboard and read-only API access to record:

- The North York Network ID and ownership.
- Its existing resources, groups, router assignments, and effective access.
- Which objects belong to Scarborough or another owner and must remain untouched.

### 1.2 Check the LAN and routing baseline

Compare the LAN resource with `estate.yaml`: North York is `10.10.10.0/24`.
Stop if ownership is ambiguous or existing routing conflicts with this deliberately
unrouted baseline. Do not silently disable an existing connection.

## 2. Prepare state and imports

### 2.1 Check provider and state safeguards

1. Review the provider pin and lock file.
2. Confirm that state, backup state, saved plans, and working data stay outside Git.
3. Confirm native state and plan encryption. Disk encryption alone is not enough.

### 2.2 Initialize and import existing objects

1. Initialize through the reviewed adapter.
2. Import the existing Network into its final resource address.
3. Import matching resources and groups. Create an object only after proving it
   does not already exist.

Do not import Scarborough, human identities, DNS, peers, or setup keys.

## 3. Review and apply the baseline

### 3.1 Validate and review the plans

Run the implemented static checks and `tofu validate` through the prepared tool
context. Review a refresh-only plan, then a normal plan.

Accept only the intended North York baseline. Explain any harmless metadata
normalization. Reject:

- Replacement or deletion of an existing Network, resource, or group.
- A router assignment or effective policy that enables LAN access.
- Unrelated-site changes, setup-key management, or secret-bearing output.
- Unencrypted or repository-local state and plan files.

### 3.2 Apply the reviewed baseline

Apply only the reviewed plan through the secret adapter. Do not use the dashboard
for routine changes after adoption.

## 4. Check

Confirm that:

- The original Network ID remains unchanged.
- The North York LAN resource exists and the router group is empty.
- No router assignment or effective routed access exists for this baseline.
- Existing connectivity and Scarborough remain unchanged.
- A new normal plan has no changes.

Record object IDs and a sanitized plan summary. Do not record full state or tokens.

## 5. Prove state recovery

### 5.1 Back up and isolate the recovery copy

Save an encrypted post-apply snapshot in independent encrypted backup storage.
Restore a copy into an isolated external directory with a separate `TF_DATA_DIR`.
Use the implemented recovery procedure; do not point it at the live state path or
migrate a live backend.

### 5.2 Verify read-only recovery

With the approved recovery material, initialize the isolated copy and obtain an
equivalent read-only refresh result. Do not apply from the recovery directory.
Stop if the backup cannot be read or resolves different managed objects.

## Stop or recover

Do not run `destroy` to undo adoption. Remove only objects proven to have been
created by this change. Leave imported objects live; after review, detach a
mistaken import from state instead of deleting the remote object.

Preserve encrypted state and recovery material. Reconcile any emergency dashboard
edit before the next OpenTofu apply.

## Sources

- [Planned change](../../openspec/changes/adopt-north-york-netbird-control-plane/).
- [OpenTofu state encryption](https://opentofu.org/docs/language/state/encryption/).
- [NetBird provider](https://registry.terraform.io/providers/netbirdio/netbird/latest/docs).
