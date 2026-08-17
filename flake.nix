{
  description = "Homelab NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }:
    let
      tooling = import ./nix/tooling.nix { inherit (nixpkgs) lib; };
      forOperatorSystems = nixpkgs.lib.genAttrs tooling.supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
      toolsFor = system: tooling.forPkgs (pkgsFor system);

      runnersFor = system:
        let
          pkgs = pkgsFor system;
          tools = toolsFor system;
          verifyRunner = pkgs.writeShellApplication {
            name = "homelab-verify";
            runtimeInputs = [
              tools.byName.bats
              tools.byName.ssh
              pkgs.coreutils
              pkgs.expect
            ];
            text = ''
              tests=( ${self}/tests/verify/*.bats )
              if [[ ''${1:-} == --list-default ]]; then
                printf '%s\n' "''${tests[@]}"
                exit 0
              fi
              if (( $# == 0 )); then
                set -- "''${tests[@]}"
              fi
              exec bats "$@"
            '';
          };
          harnessRunner = pkgs.writeShellApplication {
            name = "homelab-harness";
            runtimeInputs = [
              tools.byName.bats
              tools.byName.git
              tools.byName.jq
              tools.byName.make
              tools.byName.specbase
              pkgs.coreutils
              pkgs.expect
              pkgs.findutils
              pkgs.gawk
              pkgs.gnugrep
              pkgs.gnused
            ];
            text = ''
              export HOMELAB_ROOT="''${HOMELAB_ROOT:-$PWD}"
              export HOMELAB_VERIFY_RUNNER="${verifyRunner}/bin/homelab-verify"
              if (( $# == 0 )); then
                tests=( ${self}/tests/harness/*.bats )
                set -- "''${tests[@]}"
              fi
              exec bats "$@"
            '';
          };
        in
        {
          harness = harnessRunner;
          verify = verifyRunner;
        };

      linuxPkgs = pkgsFor "x86_64-linux";
      vmHarness = linuxPkgs.callPackage ./tests/harness/nixos-vm.nix { };
    in
    {
      # Host-agnostic attribute name: deploy with `.#nas`, not the hostname.
      # system/platform comes from nixpkgs.hostPlatform in hardware-configuration.nix.
      nixosConfigurations.nas = nixpkgs.lib.nixosSystem {
        modules = [ ./hosts/nas ];
      };

      packages = forOperatorSystems (system:
        let
          tools = toolsFor system;
        in
        {
          repo-tools = tools.repoTools;
          specbase = tools.specbase;
        });

      devShells = forOperatorSystems (system: {
        default = (toolsFor system).defaultShell;
      });

      apps = forOperatorSystems (system:
        let
          runners = runnersFor system;
          tools = toolsFor system;
        in
        {
          harness = {
            type = "app";
            program = "${runners.harness}/bin/homelab-harness";
            meta.description = "Run repository harness conformance sources";
          };
          verify = {
            type = "app";
            program = "${runners.verify}/bin/homelab-verify";
            meta.description = "Run deployed-homelab Bats verification";
          };
          specbase = {
            type = "app";
            program = "${tools.specbase}/bin/specbase";
            meta.description = "Run the repository-pinned Specbase CLI";
          };
          nixos-rebuild = {
            type = "app";
            program = "${tools.byName.deploymentAdapter}/bin/nixos-rebuild";
            meta.description = "Run the nixpkgs-pinned deployment adapter";
          };
        });

      checks = forOperatorSystems (system:
        {
          tooling-environment = (toolsFor system).toolingCheck;
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          # Focused attribute for diagnosis and forced runtime attestation.
          vm-harness-private-network = vmHarness;

          # Stable aggregate selected by `make test`. New VM tests join this
          # farm; callers continue to build the same attribute.
          vm-tests = linuxPkgs.linkFarm "homelab-vm-tests" [
            {
              name = "harness-private-network";
              path = vmHarness;
            }
          ];
        });
    };
}
