{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./zfs.nix
    ./samba.nix
    ./avahi.nix
  ];

  # Boot loader (systemd-boot / EFI).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "NASty";
  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  programs.vim.enable = true;
  programs.git.enable = true;

  # Admin user — key-based SSH, passwordless sudo.
  users.users.operator = {
    isNormalUser = true;
    description = "operator";
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOL27pePjsRIuaHTf1FLGp7Q+WFmpTE0nv4tPpsATEXP me@nathanlaundry.com"
    ];
  };
  # operator has no password set; allow wheel members to sudo without one.
  security.sudo.wheelNeedsPassword = false;

  # Let wheel members (operator) drive remote nix builds/imports as a trusted
  # nix user — required for `nixos-rebuild --build-host operator@…`, otherwise
  # importing the workstation-evaluated derivations fails the signature check.
  nix.settings.trusted-users = [ "root" "@wheel" ];

  # Enable the OpenSSH daemon.
  # NOTE: kept permissive for now (root login + password auth); tighten under
  # deferred decision D8 once the operator key login is verified.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # SSH plus SMB (139/445) for the guest-open mediaBin/smolBoy shares — see
  # ./samba.nix.
  networking.firewall.allowedTCPPorts = [
    22
    139
    445
  ];

  # This value determines the NixOS release from which the default settings for
  # stateful data were taken. Do NOT change after initial install. See
  # https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05";
}
