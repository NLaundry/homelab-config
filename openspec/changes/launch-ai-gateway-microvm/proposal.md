## Why

The AI workloads need a distinct, bounded LAN identity before application configuration is introduced. This second stack member launches only an empty, reachable `ai-gateway` MicroVM and leaves Estate modelling to a later change.

## What Changes

- Add and lock microvm.nix.
- Launch the guest at `10.10.10.20` through macvtap in bridge mode with bounded resources and default-deny ingress.
- Start the guest with NASty while leaving application services for later stack members.
- Verify the selected address is unoccupied and reserve or exclude it in OPNsense before activation; do not update the Estate inventory in this change.

## Capabilities

### Configuration

- `configuration.ai-gateway-microvm`: MicroVM runtime, macvtap, static network values, resources, and default-deny firewall (new).

### Lifecycle

- `lifecycle.ai-gateway`: guest autostart after its network prerequisite (new).

## Verification intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| `microvm-runtime`, `macvtap-lan-attachment`, `gateway-network-values`, `gateway-resource-budget`, `gateway-firewall`, `guest-autostart` | test | `tests/ai-gateway-vm.nix` | The empty guest evaluates and boots with the selected runtime, network, budget, default-deny ingress, and startup behavior. |

## Impact

- Adds microvm.nix to the flake and NASty composition.
- Adds the `ai-gateway` guest and a native NixOS KVM test exposed by the flake.
- Uses `10.10.10.20` and MAC `02:00:00:10:10:20` after a router-side collision check and reservation/exclusion.
- Does not change `estate.yaml`, Estate specs/tests, or site/address-allocation governance.
- Does not install LiteLLM or expose a guest application port.
