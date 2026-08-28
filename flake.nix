{
  description = "Homelab NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }:
    let
      tooling = import ./nix/tooling.nix { inherit (nixpkgs) lib; };
      forOperatorSystems = nixpkgs.lib.genAttrs tooling.supportedSystems;
      nasConfiguration = nixpkgs.lib.nixosSystem {
        modules = [ ./hosts/nas ];
      };
      estate = import ./nix/estate { lib = nixpkgs.lib; };
      estateFixtures = import ./nix/estate/fixtures.nix { lib = nixpkgs.lib; };
      estateObserved = import ./nix/estate/observe.nix {
        lib = nixpkgs.lib;
        inherit nasConfiguration;
      };
      estateReconciliation = import ./nix/estate/reconcile.nix {
        lib = nixpkgs.lib;
        model = estate.model;
        observed = estateObserved;
      };
      estateMutantConfiguration = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/nas
          ({ lib, ... }: {
            services.samba.enable = lib.mkForce false;
            boot.zfs.extraPools = lib.mkForce [ "smolBoy" ];
          })
        ];
      };
      estateMutantObserved = import ./nix/estate/observe.nix {
        lib = nixpkgs.lib;
        nasConfiguration = estateMutantConfiguration;
      };
      estateReconciliationMutant = import ./nix/estate/reconcile.nix {
        lib = nixpkgs.lib;
        model = estate.model;
        observed = estateMutantObserved;
      };
      estateObservedOnlyModel = estate.model // {
        workloads = builtins.removeAttrs estate.model.workloads [ "file-sharing" ];
        states = builtins.removeAttrs estate.model.states [ "mediaBin" ];
      };
      estateObservedOnlyMutant = import ./nix/estate/reconcile.nix {
        lib = nixpkgs.lib;
        model = estateObservedOnlyModel;
        observed = estateObserved;
      };
      reconciliationMutantDetected =
        builtins.any (item:
          item.code == "workload-reconciliation-mismatch"
          && item.subject == "workload:file-sharing"
        ) estateReconciliationMutant.violations
        && builtins.any (item:
          item.code == "state-reconciliation-mismatch"
          && item.subject == "state:mediaBin"
        ) estateReconciliationMutant.violations
        && builtins.any (item:
          item.code == "unexpected-observed-workload"
          && item.subject == "workload:file-sharing"
        ) estateObservedOnlyMutant.violations
        && builtins.any (item:
          item.code == "unexpected-observed-state"
          && item.subject == "state:mediaBin"
        ) estateObservedOnlyMutant.violations;
      estateFailedFixtureChecks = nixpkgs.lib.filterAttrs (_: value: !value)
        estateFixtures.checks;
      estateFailureSummary = {
        productionGraph = estate.graph;
        productionViolations = estate.violations;
        failedFixtureChecks = estateFailedFixtureChecks;
        fixtureViolations = estateFixtures.violations;
        fixtureExpectedViolations = estateFixtures.expectedViolations;
        fixtureDiffs = estateFixtures.diffs;
        reconciliation = estateReconciliation;
        missingObservationMutant = estateReconciliationMutant;
        observedOnlyMutant = estateObservedOnlyMutant;
      };
      estateChecksPassed = estate.valid && estateFixtures.all
        && estateReconciliation.valid && reconciliationMutantDetected;
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
              tools.byName.yq
              pkgs.coreutils
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
              pkgs.findutils
              pkgs.gawk
              pkgs.gnugrep
              pkgs.gnused
            ];
            text = ''
              export HOMELAB_ROOT="''${HOMELAB_ROOT:-$PWD}"
              export HOMELAB_VERIFY_RUNNER="${verifyRunner}/bin/homelab-verify"
              if (( $# == 0 )); then
                tests=( ${self}/tests/harness/*.bats ${self}/tests/estate/*.bats )
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
      nasVm = linuxPkgs.callPackage ./tests/nas-vm.nix { };
      vmSuite = import ./nix/vm-tests.nix {
        inherit (nixpkgs) lib;
        pkgs = linuxPkgs;
        inherit vmHarness nasVm;
      };
      estateCheckFor = system:
        let
          pkgs = pkgsFor system;
        in
        pkgs.runCommand "homelab-estate-registry" { } ''
          mkdir -p "$out"
          cat >"$out/graph.json" <<'EOF'
          ${builtins.toJSON estate.graph}
          EOF
          cat >"$out/production-violations.json" <<'EOF'
          ${builtins.toJSON estate.violations}
          EOF
          cat >"$out/fixture-checks.json" <<'EOF'
          ${builtins.toJSON estateFixtures.checks}
          EOF
          cat >"$out/reconciliation.json" <<'EOF'
          ${builtins.toJSON estateReconciliation}
          EOF
          cat >"$out/failure-summary.json" <<'EOF'
          ${builtins.toJSON estateFailureSummary}
          EOF
          if [ "${if estateChecksPassed then "1" else "0"}" != 1 ]; then
            printf '%s\n' 'Estate registry check failed:' >&2
            cat "$out/failure-summary.json" >&2
            exit 1
          fi
        '';
    in
    {
      # Host-agnostic attribute name: deploy with `.#nas`, not the hostname.
      # system/platform comes from nixpkgs.hostPlatform in hardware-configuration.nix.
      nixosConfigurations.nas = nasConfiguration;

      lib = {
        estateGraph = estate.graph;
        estateRegistry = {
          productionViolations = estate.violations;
          checkFailureSummary = estateFailureSummary;
          fixtureGraphs = estateFixtures.graphs;
          fixtureViolations = estateFixtures.violations;
          fixtureExpectedViolations = estateFixtures.expectedViolations;
          fixtureChecks = estateFixtures.checks;
          fixtureDiffs = estateFixtures.diffs;
          reconciliation = estateReconciliation;
          reconciliationMutant = estateReconciliationMutant;
          reconciliationObservedOnlyMutant = estateObservedOnlyMutant;
        };
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
          estate-registry = estateCheckFor system;
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") vmSuite.checks);
    };
}
