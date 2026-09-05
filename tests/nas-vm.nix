{ pkgs }:

let
  testNetwork = "192.168.251";
  mkGuest = address:
    { lib, ... }:
    {
      virtualisation = {
        memorySize = 768;
        cores = 1;
        vlans = [ ];
        interfaces.testnet0 = {
          vlan = 92;
          assignIP = false;
        };
        qemu.networkingOptions = lib.mkForce [ ];
        restrictNetwork = true;
      };
      networking = {
        useDHCP = false;
        enableIPv6 = false;
        interfaces.testnet0.ipv4.addresses = [ { inherit address; prefixLength = 24; } ];
      };
      system.stateVersion = "26.05";
    };
in
pkgs.testers.runNixOSTest {
  name = "nas-samba-behavior";
  globalTimeout = 240;
  qemu.forceAccel = true;

  nodes = {
    server = { lib, pkgs, ... }: {
      imports = [ (mkGuest "${testNetwork}.10") ../hosts/nas/samba.nix ];
      users.users.operator = {
        isNormalUser = true;
        uid = 1000;
        group = "users";
      };
      services.samba.settings.mediaBin.path = lib.mkForce "/srv/mediaBin";
      services.samba.settings.smolBoy.path = lib.mkForce "/srv/smolBoy";
      systemd.tmpfiles.rules = [
        "d /srv/mediaBin 0700 operator users -"
        "d /srv/smolBoy 0700 operator users -"
      ];
      environment.systemPackages = [ pkgs.samba ];
    };

    client = { pkgs, ... }: {
      imports = [ (mkGuest "${testNetwork}.11") ];
      boot.supportedFilesystems = [ "cifs" ];
      environment.systemPackages = [ pkgs.cifs-utils pkgs.samba ];
    };
  };

  testScript = ''
    start_all()
    server.wait_for_unit("samba-smbd.service")
    server.wait_for_open_port(445)
    client.wait_for_unit("multi-user.target")

    for node, address in [
        (server, "${testNetwork}.10"),
        (client, "${testNetwork}.11"),
    ]:
        node.succeed("test ! -e /sys/class/net/eth0")
        node.succeed("test -e /sys/class/net/testnet0")
        node.succeed(f"ip -4 -o addr show dev testnet0 | grep -F '{address}/24'")
        node.succeed("test \"$(ip -4 -o addr show scope global | wc -l)\" -eq 1")
        node.fail("ip -4 route show default | grep -q .")
        node.fail("ip -4 route get 10.10.10.1")

    listing = client.succeed("smbclient -N -L //${testNetwork}.10")
    assert "mediaBin" in listing, listing
    assert "smolBoy" in listing, listing

    for share in ["mediaBin", "smolBoy"]:
        mountpoint = f"/mnt/{share}"
        fixture = f"{mountpoint}/vm-round-trip.txt"
        client.succeed(f"mkdir -p {mountpoint}")
        client.succeed(
            f"mount -t cifs //${testNetwork}.10/{share} {mountpoint} "
            "-o guest,vers=3.1.1"
        )
        client.succeed(f"printf '%s\\n' '{share} guest round trip' > {fixture}")
        client.succeed(f"grep -Fx '{share} guest round trip' {fixture}")
        server.succeed(f"test $(stat -c %u /srv/{share}/vm-round-trip.txt) -eq 1000")
        client.succeed(f"rm -- {fixture}")
        client.succeed(f"umount {mountpoint}")
  '';
}
