## Context

NASty is the only production NixOS host. It has KVM, four CPUs, 31 GiB RAM, and active Ethernet `enp2s0` using NetworkManager/DHCP at `10.10.10.11/24`. A host bridge would risk the SSH deployment path, so the empty guest should obtain its own LAN identity without moving NASty's address. Estate and broader network-allocation modelling are intentionally deferred.

## Goals / Non-Goals

**Goals:**

- Boot an empty `ai-gateway` MicroVM at `10.10.10.20` after checking and reserving the address.
- Preserve NASty's existing NIC and management address.
- Prove default-deny ingress and KVM test isolation.

**Non-Goals:**

- Estate inventory changes, broader network allocation policy, LiteLLM, OpenMemory, application listeners, provider egress tests, or guest state volumes.

## Decisions

- Use flake-locked microvm.nix with QEMU/KVM.
- Attach MAC `02:00:00:10:10:20` through macvtap in `bridge` mode on `enp2s0`.
- Configure `10.10.10.20/24`, gateway `10.10.10.1`, and DNS `10.10.10.1` only after an OPNsense collision check and reservation/exclusion.
- Limit the guest to 2 vCPUs and 4 GiB RAM.
- Deny unsolicited trusted-LAN ingress until a later stack member selects a service listener.
- Accept macvtap's NASty-to-guest limitation; verify production reachability from another LAN client.
- Keep the guest definition workload-specific until a second MicroVM proves a reusable abstraction is needed.

## Enforcement design

### `tests/ai-gateway-vm.nix`

- Register a forced-KVM private NixOS test with exact repository-required network-isolation declarations.
- Assert boot, runtime selection, resource limits, static values, default-deny firewall, and autostart behavior.
- Wire the source through `flake.nix` and `nix/vm-tests.nix`.
- Fail on assertion or timeout.
- This does not exercise macvtap, OPNsense, or the physical LAN.

## Risks / Trade-offs

- **[Static address conflicts]** -> Check the current router state and reserve/exclude `.20` for the selected MAC before activation.
- **[Host cannot reach macvtap guest]** -> Probe from a separate LAN client; add a host-only interface only when a real dependency appears.
- **[Remote activation affects NASty]** -> Build first, use temporary activation, and prove rollback leaves NetworkManager and `10.10.10.11` unchanged.
- **[Inventory temporarily omits the guest]** -> Keep Estate modelling explicitly out of scope and add it later as a dedicated network/Estate change.

## Migration Plan

1. Add and lock microvm.nix, then build the full NASty closure.
2. Register and pass the isolated empty-guest KVM test.
3. Confirm `.20` is unused and reserve/exclude it in OPNsense.
4. Activate temporarily and verify from another LAN client.
5. Rollback removes the guest unit without modifying NASty's NIC profile.
