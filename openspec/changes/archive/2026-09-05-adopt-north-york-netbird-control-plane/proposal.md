## Why

The existing North York NetBird Network is outside repository control. Adopt it into OpenTofu before OPNsense enrollment so later routing changes can build on known state without recreating the Network.

## What Changes

- Extend the existing NetBird OpenTofu root to declare the North York Network, its dedicated resource group, and its `10.10.10.0/24` LAN resource.
- Pin and lock the official NetBird provider.
- Inspect and import matching live objects before creating anything missing.
- Keep natively encrypted local state and working data outside Git.
- Use direct SecretSpec-scoped OpenTofu commands; add no custom secret or command adapter.
- Add no peer, router group, router assignment, access policy, DNS object, setup key, OPNsense change, or Scarborough object.
- Recover lost local state by inspecting and re-importing the three managed objects; add no separate backup system.

## Capabilities

### New Capabilities

- `governance/network-iac`: OpenTofu is the reproducible repository authority for the selected NetBird objects, while operational state remains outside Git.
- `configuration/netbird`: NetBird declares the North York Network, dedicated resource group, and LAN resource without routing.
- `lifecycle/netbird-control`: Import and apply preserve existing NetBird object identity and unrelated account state.

### Modified Capabilities

None.

## Verification intent

| Covered truth | Planned proof |
|---|---|
| NetBird configuration is reproducible | One local check runs formatting, locked initialization, and `tofu validate` with no production credentials. |
| State stays outside Git | The local check rejects tracked state and OpenTofu working data. |
| Only the North York baseline is declared | The local check allows one peer-free resource group and rejects routers, policies, DNS, setup keys, and Scarborough declarations. |
| Existing objects keep their identity | Live inventory and import precede one reviewed plan; replacement, deletion, routing, or unrelated changes stop the operation. |
| Adoption converges | A final scoped plan reports no changes. |

## Impact

- Extends `infra/netbird/` with three managed NetBird objects.
- Adds one small IaC check and a concise operating procedure.
- Uses the existing SecretSpec scope and state-encryption input.
- Makes no OPNsense or effective network-routing change.
