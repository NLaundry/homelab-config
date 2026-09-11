{ ... }:

let
  mac = "02:4c:4c:10:00:12";
in
{
  imports = [ ./service.nix ];
  networking.hostName = "step-ca";
  system.stateVersion = "26.05";

  microvm = {
    hypervisor = "qemu";
    vcpu = 1;
    mem = 1024;
    interfaces = [{
      type = "tap";
      id = "tap-step-ca";
      inherit mac;
    }];
    # No host directory shares, especially no root-custody share.
    # Provision this image explicitly once; never recreate missing state at boot.
    volumes = [{
      image = "/smolBoy/services/step-ca/state.img";
      mountPoint = "/var";
      label = "step-ca-state";
      fsType = "ext4";
      autoCreate = false;
    }];
  };

  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.networks."10-lan" = {
    matchConfig.MACAddress = mac;
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = false;
      LinkLocalAddressing = "no";
    };
    dhcpV4Config.ClientIdentifier = "mac";
  };

  users.users.operator = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
  security.sudo.wheelNeedsPassword = false;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
    hostKeys = [{
      path = "/var/lib/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };
  services.timesyncd.enable = true;

  # Before private commissioning, the CA deliberately fails its startup checks.
}
