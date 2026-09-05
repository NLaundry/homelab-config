{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./zfs.nix
    ./samba.nix
    ./avahi.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "NASty";
  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  programs.vim.enable = true;
  programs.git.enable = true;

  users.users.operator = {
    isNormalUser = true;
    description = "operator";
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOL27pePjsRIuaHTf1FLGp7Q+WFmpTE0nv4tPpsATEXP me@nathanlaundry.com"
    ];
  };
  # Allow remote administration without an account password.
  security.sudo.wheelNeedsPassword = false;

  # Trust administrators so remote builds can store their results.
  nix.settings.trusted-users = [ "root" "@wheel" ];

  # Keep recovery access until key-only login is tested.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 ];

  # Keep the install version so upgrades preserve existing data settings.
  system.stateVersion = "26.05";
}
