## Why

North York NetBird objects currently exist outside repository authority, and later router enrollment cannot safely depend on dashboard-only state. This change adopts only the North York control-plane model into OpenTofu while deliberately leaving it unrouted and behaviorally inert.

## What Changes

- Add a reusable OpenTofu root and site module for NetBird Networks, groups, and resources.
- Pin the official NetBird provider and commit its dependency lock information.
- Import the existing North York Network where present; create only missing North York baseline objects.
- Declare the North York LAN resource and an initially empty North York router group.
- Do not create a Network router assignment or an effective LAN-access policy.
- Make OpenTofu the sole change authority for managed NetBird objects; retain the dashboard for inspection and emergency diagnosis.
- Keep encrypted local state outside Git, back it up through the operator's encrypted backup boundary, and document import/recovery operations.
- Leave every Scarborough object unmanaged and unchanged.

## Planes

### Governance

- `governance.network-iac`: OpenTofu is the reproducible and exclusive repository control path for managed NetBird control-plane objects (new).

### Configuration

- `configuration.netbird`: the pinned NetBird provider declares a North York Network and resources with no routing peer assigned (new).

### Lifecycle

- `lifecycle.netbird-control`: adoption/import and state recovery preserve remote NetBird behavior and avoid destructive recreation (new).

## Enforcement intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| `netbird-control-plane-authority` | test | `tests/iac/netbird-contracts.bats` | Managed NetBird object declarations have one OpenTofu root and no competing Ansible/dashboard mutation path in repository automation. |
| `netbird-iac-reproducible` | command | `tests/iac/netbird-static-check` | Formatting, initialization against a disposable state location, provider locking, validation, and module tests succeed without production credentials. |
| `netbird-state-excluded-from-git` | test | `tests/iac/netbird-contracts.bats` | Plaintext or encrypted state, plan files, and OpenTofu working data are absent from tracked files and directed to the external state path. |
| `north-york-network-declared` | command | `tests/iac/netbird-static-check` | The reusable module resolves exactly the North York Network, LAN resource, and router group from test data. |
| `north-york-routing-unassigned` | test | `tests/iac/netbird-contracts.bats` | The baseline contains no Network router resource and no enabled policy granting routed LAN access. |
| `netbird-provider-pinned` | command | `tests/iac/netbird-static-check` | The provider constraint and lock selection are present and `tofu validate` accepts the root. |
| `netbird-adoption-preserves-service` | manual | `docs/operations/netbird-opentofu.md#import-existing-north-york` | The reviewed adoption plan contains no destroy/recreate, routing assignment, or unrelated-site change before apply. |
| `netbird-state-recoverable` | manual | `docs/operations/netbird-opentofu.md#state-recovery-drill` | An encrypted state backup restores into an isolated path and produces the same read-only refresh result. |

## Impact

- Adds `infra/netbird/`, a reusable site module, OpenTofu command adapters, IaC checks, and `docs/operations/netbird-opentofu.md`.
- Uses the SOPS process boundary established by the preceding stack member for `NB_PAT`, `NB_MANAGEMENT_URL`, and the state-encryption input.
- Adopts North York NetBird objects but creates no routing peer, route activation, DNS setting, setup key, OPNsense change, or Scarborough management.
