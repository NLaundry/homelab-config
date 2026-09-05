{
  description = "Homelab NixOS configurations";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      forSystems = lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ];
    in
    {
      # Platform comes from the host's hardware configuration.
      nixosConfigurations.nas = lib.nixosSystem {
        modules = [ ./hosts/nas ];
      };

      devShells = forSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          dev = import ./nix/dev.nix { inherit pkgs; };
        in
        {
          default = pkgs.mkShell { packages = dev.packages; };
        });

      apps = forSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          dev = import ./nix/dev.nix { inherit pkgs; };
        in
        {
          verify = {
            type = "app";
            meta.description = "Run deployed-homelab checks";
            program = lib.getExe (pkgs.writeShellApplication {
              name = "homelab-verify";
              runtimeInputs = [ pkgs.bats dev.ssh pkgs.yq-go pkgs.coreutils ];
              text = ''
                if (( $# == 0 )); then
                  set -- ${self}/tests/verify/*.bats
                fi
                exec bats "$@"
              '';
            });
          };
          nixos-rebuild = {
            type = "app";
            meta.description = "Run the pinned NixOS deployment tool";
            program = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
          };
        });

      checks.x86_64-linux.nas-samba =
        nixpkgs.legacyPackages.x86_64-linux.callPackage ./tests/nas-vm.nix { };
    };
}
