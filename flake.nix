{
  description = "Homelab NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }: {
    # Host-agnostic attribute name: deploy with `.#nas`, not the hostname.
    # system/platform comes from nixpkgs.hostPlatform in hardware-configuration.nix.
    nixosConfigurations.nas = nixpkgs.lib.nixosSystem {
      modules = [ ./hosts/nas ];
    };
  };
}
