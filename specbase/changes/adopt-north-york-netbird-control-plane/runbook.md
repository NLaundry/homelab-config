# User runbook: adopt the North York NetBird control plane

## Why you are needed

Importing a live cloud object and accepting its state cannot be proven safely from repository fixtures. You confirm which live objects belong to North York, approve the first plan, and confirm independent state backup.

## Prerequisites

Do not begin until the preceding secret proposal is applied and its read-only NetBird authentication check passes. Have access to the NetBird dashboard for inspection only.

## When to act

### Task 3.2: identify the live North York baseline

In the NetBird dashboard, confirm and record sanitized identifiers for:

- the existing North York Network, if present
- its current description and resources
- any existing North York group intended for adoption
- whether a router is currently assigned

Explicitly identify any Scarborough objects so they can be excluded. Do not edit objects in the dashboard during this inventory.

Stop if North York already routes traffic unexpectedly or if ownership of an object is ambiguous.

### Tasks 3.3–3.4: approve import and plan

After the implementation prepares exact import addresses:

1. Review the import list before it runs.
2. Review the refresh-only plan.
3. Review the normal plan.
4. Approve apply only if the plan has no destroy/recreate, router assignment, effective LAN-access policy, setup key, secret value, DNS object, or Scarborough change.

Harmless label/description normalization must be explained explicitly. Reject unexplained drift.

### Task 3.5: confirm the unrouted result

After apply, inspect the dashboard and confirm:

- the North York Network still has no routing peer
- its LAN resource and empty router group exist as planned
- existing peer connectivity is unaffected
- Scarborough is unchanged

Do not make a corrective dashboard edit; return drift to the OpenTofu configuration.

### Task 4.1: confirm state backup and recovery

Confirm the external state directory is outside the repository and included in independently encrypted backup. Perform the documented isolated recovery drill. The restored state must produce the same read-only refresh result without applying a change.

## Stop conditions

Stop if a plan proposes:

- deleting or replacing an existing Network
- assigning a router or granting routed access
- managing Scarborough
- storing a setup key or credential
- writing state, backups, plans, or `.terraform` data into Git
- using unencrypted state

## Evidence to record

Record object IDs, state/backup hashes, plan action counts, provider versions, and pass/fail conclusions. Do not record state bodies, plans containing sensitive fields, PATs, or environment output.
