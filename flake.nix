{
  description = "Homelab NixOS configurations";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  # SecretSpec 0.20 includes SOPS and scoped extraction; leave host packages unchanged.
  inputs.secretTools.url = "github:NixOS/nixpkgs/801bef6abd86b91e51083066b83fb354a11fc640";

  outputs = { self, nixpkgs, secretTools, ... }:
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
          dev = import ./nix/dev.nix {
            inherit pkgs;
            secretspec = secretTools.legacyPackages.${system}.secretspec;
          };
        in
        {
          default = pkgs.mkShell { packages = dev.packages; };
        });

      apps = forSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          dev = import ./nix/dev.nix {
            inherit pkgs;
            secretspec = secretTools.legacyPackages.${system}.secretspec;
          };
        in
        {
          verify = {
            type = "app";
            meta.description = "Run deployed-homelab checks";
            program = lib.getExe (pkgs.writeShellApplication {
              name = "homelab-verify";
              runtimeInputs = [ pkgs.bats dev.ssh pkgs.yq-go pkgs.coreutils ];
              text = ''
                preflight=false
                if [[ ''${1:-} == --preflight ]]; then
                  preflight=true
                  shift
                fi
                if (( $# == 0 )); then
                  set -- ${self}/tests/verify/*.bats
                fi
                if [[ $preflight == true ]]; then
                  for test_file in "$@"; do
                    if [[ ! -f $test_file ]]; then
                      printf 'Activation verification needs explicit test files, not Bats options: %s\n' "$test_file" >&2
                      exit 1
                    fi
                    case "$test_file" in
                      */deployment.bats) ;;
                      */nas-samba.bats)
                        # shellcheck source=/dev/null
                        source ${self}/tests/verify/lib/nas-samba-safety.sh
                        require_smb_tools
                        ;;
                      *) printf 'Unknown activation verification suite: %s\n' "$test_file" >&2; exit 1 ;;
                    esac
                  done
                  printf 'Post-activation verification files:\n'
                  printf '  %s\n' "$@"
                  exit 0
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
