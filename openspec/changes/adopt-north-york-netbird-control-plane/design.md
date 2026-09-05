## Context

The repository has no OpenTofu root or tracked NetBird declarations. A North York Network was created manually during exploration, while Scarborough may also contain unrelated manual objects. The preceding stack member supplies SOPS-protected `NB_PAT`/`NB_MANAGEMENT_URL` delivery and OpenTofu tooling. This change must establish authority without accidentally activating LAN routing or absorbing the second site.

## Goals / Non-Goals

**Goals:**
- Establish a reusable, pinned NetBird OpenTofu root and site module.
- Adopt only the existing North York Network and model its LAN resource.
- Create an empty router group that a later enrolled OPNsense peer can join.
- Produce a reviewed non-disruptive baseline plan.
- Keep encrypted, recoverable state outside Git.

**Non-Goals:**
- Install or enroll NetBird on OPNsense.
- Assign a Network router or enable LAN access.
- Manage DNS, setup keys, peers, Scarborough, or human identity.
- Convert every pre-existing NetBird account object to code.

## Decisions

### One OpenTofu root with a reusable site module

Place the root under `infra/netbird/` and a reusable module under `infra/netbird/modules/site-network/`. The module accepts a site key, display name, resource definitions, and router-group name. The North York call is the only site instance in this change; no empty Scarborough placeholder exists.

### Import before convergence

Inventory the live North York object and import it into the matching resource address before any apply. Create objects only when live inspection proves they do not exist. The first reviewed plan may normalize harmless description/label metadata, but it must contain no destroy/recreate, routing assignment, policy activation, or change outside North York.

### Deliberately unrouted baseline

Declare the North York Network, its LAN CIDR resource, and an empty router group. Do not declare `netbird_network_router` or an effective policy that grants access to the resource. This creates a safe prefix: control-plane state is managed while LAN traffic remains unchanged.

### Pinned provider and generated lock

Use the official NetBird provider with an exact compatible constraint selected during implementation and commit the generated provider lock file for every supported operator platform. Upgrades require an explicit reviewed change, not an unconstrained initialization.

### External encrypted local state

Use the local backend at `${XDG_STATE_HOME:-$HOME/.local/state}/homelab-config/netbird/terraform.tfstate`, outside the repository. Configure OpenTofu native state/plan encryption from SOPS-delivered runtime material and keep `TF_DATA_DIR` beside the external state. Copy encrypted post-apply snapshots into an external directory included in the operator's encrypted backup set. Track neither state, backup state, plan files, nor `.terraform` working data.

This avoids bootstrapping a remote backend for a two-admin homelab while preserving a path to migrate later. Full-disk encryption is not treated as the only state protection.

### Dashboard inspection only

After adoption, routine writes to managed objects use OpenTofu. The NetBird dashboard remains useful for inspection and emergency diagnosis; any emergency edit must be imported/reconciled before the next apply.

## Verification design

- `tests/iac/netbird-contracts.bats` inspects tracked IaC and Git state. It rejects state/plan/working files, setup-key resources, Scarborough declarations, router resources, and enabled routed-access policies in this prefix. It also checks one root/module ownership path. It proves repository structure, not remote state.
- `tests/iac/netbird-static-check` runs formatting, disposable-backend initialization, provider lock verification, `tofu validate`, and module tests using non-secret North York fixture data. A non-zero child result fails the command. It does not authenticate to NetBird.
- The import procedure in `docs/operations/netbird-opentofu.md` captures a sanitized live inventory and reviewed plan summary. The operator rejects replacement, routing, unrelated-site, or secret-bearing output before apply. This is manual because the current cloud account is outside CI.
- The state recovery drill copies an encrypted backup into an isolated external directory, initializes without migration, and performs a read-only refresh/plan through the secret adapter. Evidence records hashes and plan summary only.

## Risks / Trade-offs

- [Wrong import address can propose recreation] -> Require live inventory, exact resource address, and a no-destroy reviewed plan before apply.
- [Local state can be lost with the operator machine] -> Encrypt state natively and require an external encrypted backup plus recovery drill.
- [A dashboard edit creates drift] -> Make OpenTofu the declared authority and require reconciliation before subsequent apply.
- [Provider behavior changes] -> Pin the provider and lock platforms; upgrades are explicit.
- [A broad LAN resource exposes too much later] -> This prefix grants no route or policy; activation separately reviews resource granularity.
- [Scarborough objects are accidentally imported] -> Contract tests and plan review reject non-North-York declarations and changes.

## Migration Plan

1. Create the root/module, external-state adapter, ignore rules, static checks, and runbook with fixture data only.
2. Inventory the live NetBird account and record only sanitized North York object IDs in the operator procedure.
3. Initialize encrypted external state and import the existing North York Network at its final resource address.
4. Import or create the North York LAN resource and empty router group as live state requires.
5. Review a refresh-only plan and then a normal plan; proceed only without replacement, router assignment, effective LAN access, or unrelated-site changes.
6. Apply the accepted baseline, create an encrypted state backup, and perform the recovery drill.
7. Roll back by removing only objects proven to have been created by this change; imported pre-existing objects remain live and can be removed from state without remote deletion.
