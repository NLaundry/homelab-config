## 1. Declare the empty guest

- [ ] 1.1 Add and lock `microvm.nix`, compose its host module into `nixosConfigurations.nas`, and add workload-specific NASty/guest modules.
- [ ] 1.2 Configure QEMU/KVM, 2 vCPUs, 4 GiB RAM, macvtap `bridge` mode on `enp2s0`, MAC `02:00:00:10:10:20`, `10.10.10.20/24`, gateway/DNS `10.10.10.1`, and default-deny ingress.
- [ ] 1.3 Confirm `.20` is unoccupied, then reserve or exclude it for the selected MAC in OPNsense before activation and record sanitized confirmation.

## 2. Deliver MicroVM evidence

- [ ] 2.1 Implement `tests/ai-gateway-vm.nix`, register it through `flake.nix` and `nix/vm-tests.nix`, and include exact `qemu.networkingOptions = lib.mkForce [ ];` and `restrictNetwork = true;` declarations.
- [ ] 2.2 Assert runtime selection, boot, resource limits, static values, default-deny firewall, and guest autostart in the private forced-KVM topology.
- [ ] 2.3 Confirm bindings `ai-gateway-vm-configuration` and `ai-gateway-transitions`; execute the VM source through its native harness.
- [ ] 2.4 Add direct requirement observations for automated bindings, run enforcement-quality with this change's spec root, and validate this change strictly after sources exist.

## 3. Activate and verify the empty guest

- [ ] 3.1 Build the complete NASty closure, activate temporarily, and verify `10.10.10.20` from a separate trusted-LAN client.
- [ ] 3.2 Verify rollback removes/disables the guest while preserving NASty's NetworkManager profile, DHCP attachment, and `10.10.10.11` management reachability.
