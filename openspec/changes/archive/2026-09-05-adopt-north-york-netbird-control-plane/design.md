## Context

The preceding change created the pinned NetBird provider, SecretSpec credential delivery, and native OpenTofu state encryption. A North York Network may already exist in NetBird, while Scarborough and all peers remain outside this change.

## Goals / Non-Goals

**Goals:**
- Manage the North York Network, a dedicated peer-free resource group, and its `10.10.10.0/24` LAN resource in one OpenTofu root.
- Preserve existing object identity through inspection and import.
- Leave the Network unrouted.

**Non-Goals:**
- Reusable multi-site modules.
- Peers, router groups, router assignments, policies, DNS, setup keys, or OPNsense configuration.
- Dedicated state-backup infrastructure or a recovery drill.

## Decisions

### Keep the three resources in the existing root

Declare the North York Network, dedicated resource group, and LAN resource directly under `infra/netbird/`. The resource group has no peers and exists only because the provider requires every Network resource to belong to a group. A reusable site module is premature while only one site and three objects are managed.

Read the selected LAN CIDR from `estate.yaml` so the repository does not duplicate that boundary. Declare no Scarborough placeholder.

### Import before creation

Use read-only account inventory to identify exact North York matches and current routing state. Stop if ownership is ambiguous or routing is unexpectedly active. Import matching objects into their final addresses before planning; create an object only when inventory proves it absent.

### Keep the baseline unrouted

Declare no peer, router group, router, policy, DNS, or setup-key resource. The one resource group contains no peers and grants no access without a policy. OPNsense enrollment and routing remain later changes.

### Use direct scoped OpenTofu commands

Run OpenTofu directly through the existing `opentofu` SecretSpec scope. Set `TF_DATA_DIR` and the local backend path under `${XDG_STATE_HOME:-$HOME/.local/state}/homelab-config/netbird/`. Keep native state and plan encryption enabled. Add no wrapper that handles secrets.

If local state is lost, inspect NetBird and re-import the Network, resource group, and LAN resource. Three re-importable objects do not justify separate backup infrastructure.

### Use one local check

A single `tests/iac/netbird-static-check` command covers formatting, disposable locked initialization, validation, Git state exclusion, and exactly one peer-free resource group, and absence of forbidden NetBird declarations. It does not authenticate to NetBird or test provider behavior.

## Risks / Trade-offs

- [A wrong import could cause replacement] -> Inventory exact IDs first and stop on any replacement or deletion in the plan.
- [Local state could be lost] -> State remains encrypted and external; recover by re-importing the two live objects.
- [A broad resource could later expose the LAN] -> This change creates no router or access policy; routing requires a separate reviewed change.
- [Unrelated account objects could be absorbed] -> Declare and import only the uniquely identified North York Network, resource group, and LAN resource.

## Migration Plan

1. Extend the root and pass the local check with dummy inputs.
2. Inventory the live North York Network, resource, and routing state without mutation.
3. Initialize encrypted external state and import exact matches for the Network, resource group, and LAN resource.
4. Review one normal plan; apply only missing baseline objects or harmless metadata normalization.
5. Confirm a final scoped plan has no changes. Roll back mistaken adoption with reviewed state removal, not remote destruction.
