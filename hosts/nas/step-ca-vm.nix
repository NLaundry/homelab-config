{ config, pkgs, ... }:

let
  operatorKeys = config.users.users.operator.openssh.authorizedKeys.keys;
in
{
  # NetworkManager owns the physical uplink and the separately approved bridge.
  # microvm.nix alone owns this exact TAP; do not enable host networkd.
  networking.networkmanager.unmanaged = [ "interface-name:tap-step-ca" ];
  # Do not enable host memory deduplication just to run this one guest.
  hardware.ksm.enable = false;

  microvm.vms.step-ca = {
    # Existing private state, recovery copy and service restart are verified.
    autostart = true;
    restartIfChanged = false;
    config = {
      imports = [ ../../guests/step-ca ];
      users.users.operator.openssh.authorizedKeys.keys = operatorKeys;
    };
  };

  systemd.services."microvm-tap-interfaces@step-ca" = {
    requires = [ "NetworkManager.service" "NetworkManager-wait-online.service" ];
    after = [ "NetworkManager.service" "NetworkManager-wait-online.service" ];
    postStart = ''
      test -d /sys/class/net/br-lan/bridge
      ${pkgs.iproute2}/bin/ip link set tap-step-ca master br-lan
    '';
  };

  systemd.services."microvm@step-ca" = {
    requires = [ "zfs-mount.service" ];
    after = [ "zfs-mount.service" ];
    unitConfig.RequiresMountsFor = [ "/smolBoy/services/step-ca" ];
    preStart = ''
      test "$(${pkgs.util-linux}/bin/findmnt -rn -o SOURCE -T /smolBoy/services/step-ca)" = smolBoy/services/step-ca
      test -s /smolBoy/services/step-ca/state.img
    '';
    # Missing storage is an operator recovery case, not a restart loop.
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = 30;
    unitConfig.StartLimitBurst = 3;
    unitConfig.StartLimitIntervalSec = 300;
  };
}
