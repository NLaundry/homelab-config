{ pkgs }:

let
  testNetwork = "192.168.250";

  mkGuest = address:
    { lib, ... }:
    {
      virtualisation = {
        memorySize = 512;
        cores = 1;
        vlans = [ ];
        interfaces.testnet0 = {
          vlan = 91;
          assignIP = false;
        };
        # Remove QEMU's implicit SLiRP NIC. The declared test-driver VLAN is
        # the guest's only non-loopback network.
        qemu.networkingOptions = lib.mkForce [ ];
        restrictNetwork = true;
      };

      networking = {
        useDHCP = false;
        enableIPv6 = false;
        firewall.enable = false;
        interfaces.testnet0.ipv4.addresses = [
          {
            inherit address;
            prefixLength = 24;
          }
        ];
      };

      system.stateVersion = "26.05";
    };
in
pkgs.testers.runNixOSTest {
  name = "harness-private-network";
  globalTimeout = 180;
  qemu.forceAccel = true;

  nodes = {
    alpha = mkGuest "${testNetwork}.10";
    beta = mkGuest "${testNetwork}.11";
  };

  testScript = ''
    start_all()

    alpha.wait_for_unit("multi-user.target")
    beta.wait_for_unit("multi-user.target")

    for node, own_address, peer_address in [
        (alpha, "${testNetwork}.10", "${testNetwork}.11"),
        (beta, "${testNetwork}.11", "${testNetwork}.10"),
    ]:
        node.succeed("test ! -e /sys/class/net/eth0")
        node.succeed("test -e /sys/class/net/testnet0")
        node.succeed(
            f"ip -4 -o addr show dev testnet0 | awk '{{ print $4 }}' | "
            f"grep -Fx '{own_address}/24'"
        )
        node.succeed("test \"$(ip -4 -o addr show scope global | wc -l)\" -eq 1")
        node.succeed("ip -4 route show | grep -Eq '^192\\.168\\.250\\.0/24 dev testnet0'")
        node.succeed("test \"$(ip -4 route show | wc -l)\" -eq 1")
        node.fail("ip -4 route show default | grep -q .")
        node.fail("ip -4 route get 10.10.10.1")
        node.succeed(f"ping -c 1 -W 2 {peer_address}")
  '';
}
