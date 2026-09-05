## 1. Declare the empty guest

- [ ] 1.1 Add and lock `microvm.nix`, compose its host module into `nixosConfigurations.nas`, and add workload-specific NASty/guest modules.
- [ ] 1.2 Configure QEMU/KVM, 2 vCPUs, 4 GiB RAM, macvtap `bridge` mode on `enp2s0`, MAC `02:00:00:10:10:20`, `10.10.10.20/24`, gateway/DNS `10.10.10.1`, and default-deny ingress.
- [ ] 1.3 Confirm `.20` is unoccupied, then reserve or exclude it for the selected MAC in OPNsense before activation and record sanitized confirmation.

## 2. Deliver MicroVM evidence

- [ ] 2.1 Implement `tests/ai-gateway-vm.nix` as a native NixOS test exposed through `flake.nix`, and include exact `qemu.networkingOptions = lib.mkForce [ ];` and `restrictNetwork = true;` declarations.
- [ ] 2.2 Assert runtime selection, boot, resource limits, static values, default-deny firewall, and guest autostart in the private forced-KVM topology.
- [ ] 2.3 Build and execute the native NixOS VM test on an explicitly selected KVM-capable test store and record results.
- [ ] 2.4 Run `make check` for Nix evaluation and separately run `openspec validate launch-ai-gateway-microvm --strict` after sources exist. `make check` does not execute VM tests, OpenSpec, or shell tests.

## 3. Activate and verify the empty guest

- [ ] 3.1 Build the complete NASty closure, activate temporarily, and verify `10.10.10.20` from a separate trusted-LAN client.
- [ ] 3.2 Verify rollback removes/disables the guest while preserving NASty's NetworkManager profile, DHCP attachment, and `10.10.10.11` management reachability.
