{ lib }:

let
  supportedSystems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];
in
{
  inherit supportedSystems;

  forPkgs = pkgs:
    let
      specbase = pkgs.callPackage ./specbase.nix { };

      platformAdapters = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        ssh = "/usr/bin/ssh";
      };

      darwinSshAdapter = pkgs.writeShellApplication {
        name = "ssh";
        text = ''
          if [[ ! -x ${platformAdapters.ssh} ]]; then
            printf 'required macOS SSH transport is unavailable: %s\n' \
              ${lib.escapeShellArg platformAdapters.ssh} >&2
            exit 127
          fi
          exec ${platformAdapters.ssh} "$@"
        '';
      };

      byName = {
        ansible = pkgs.ansible;
        bats = pkgs.bats;
        deploymentAdapter = pkgs.nixos-rebuild;
        git = pkgs.git;
        jq = pkgs.jq;
        make = pkgs.gnumake;
        shellcheck = pkgs.shellcheck;
        shfmt = pkgs.shfmt;
        specbase = specbase;
        ssh = if pkgs.stdenv.hostPlatform.isDarwin then darwinSshAdapter else pkgs.openssh;
        yq = pkgs.yq-go;
      };

      commandPackages = {
        ansible = byName.ansible;
        ansible-playbook = byName.ansible;
        bats = byName.bats;
        git = byName.git;
        jq = byName.jq;
        make = byName.make;
        nixos-rebuild = byName.deploymentAdapter;
        shellcheck = byName.shellcheck;
        shfmt = byName.shfmt;
        specbase = byName.specbase;
        ssh = byName.ssh;
        yq = byName.yq;
      };

      directCommands = builtins.attrNames commandPackages;
      directPackages = lib.unique (builtins.attrValues commandPackages);

      repoTools = pkgs.buildEnv {
        name = "homelab-repo-tools";
        paths = directPackages;
        pathsToLink = [ "/bin" ];
        passthru = {
          inherit directCommands directPackages platformAdapters supportedSystems;
          packageNames = map lib.getName directPackages;
        };
        meta.description = "Direct operator tools for homelab-config";
      };

      defaultShell = pkgs.mkShell {
        name = "homelab-config";
        packages = [ repoTools ];
        passthru = {
          inherit repoTools directCommands;
        };
      };

      toolingCheck = pkgs.runCommand "homelab-tooling-environment" {
        nativeBuildInputs = [ repoTools ];
      } ''
        for commandName in ${lib.escapeShellArgs directCommands}; do
          commandPath=$(command -v "$commandName")
          case "$commandPath" in
            ${repoTools}/bin/*) ;;
            *)
              printf 'command is not supplied by repo-tools: %s -> %s\n' \
                "$commandName" "$commandPath" >&2
              exit 1
              ;;
          esac
        done
        mkdir -p $out
      '';
    in
    {
      inherit
        byName
        commandPackages
        defaultShell
        directCommands
        directPackages
        platformAdapters
        repoTools
        specbase
        toolingCheck
        ;
    };
}
