{
  description = "Homelab NixOS configurations";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  # SecretSpec 0.20 includes SOPS and scoped extraction; leave host packages unchanged.
  inputs.secretTools.url = "github:NixOS/nixpkgs/801bef6abd86b91e51083066b83fb354a11fc640";

  inputs.microvm.url = "github:microvm-nix/microvm.nix/804cbac7a462aa0fa8bb60c3d2fc4ead0a62060f";
  inputs.microvm.inputs.nixpkgs.follows = "nixpkgs";
  inputs.sops-nix.url = "github:Mic92/sops-nix/fbf759290e0cb0a98dfc813a4eb7d53ad1dacb57";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, secretTools, microvm, sops-nix, ... }:
    let
      inherit (nixpkgs) lib;
      forSystems = lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ];
    in
    {
      # Platform comes from the host's hardware configuration.
      nixosConfigurations.nas = lib.nixosSystem {
        modules = [
          microvm.nixosModules.host
          ./hosts/nas
          { microvm.vms.step-ca.config.imports = [ sops-nix.nixosModules.sops ]; }
        ];
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
          default = pkgs.mkShell {
            inherit (dev) packages shellHook;
          };
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
              runtimeInputs = [ pkgs.bats dev.ssh pkgs.yq-go pkgs.coreutils pkgs.curl pkgs.openssl pkgs.dnsutils pkgs.cacert ];
              text = ''
                preflight=false
                if [[ ''${1:-} == --preflight ]]; then
                  preflight=true
                  shift
                fi
                # Non-secret probe context is derived from the repository's own
                # declarations so discovered probes run without manual opt-in.
                # Operator-supplied values always win.
                estate=${self}/estate.yaml
                # The published private root joins the runner's normal trust
                # (standard CAs + LaundryLab root) so probes exercise real trust
                # paths instead of --cacert overrides or insecure modes.
                trust_bundle=$(mktemp)
                cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt \
                  ${self}/certificates/laundrylab-root-ca.crt > "$trust_bundle" 2>/dev/null || true
                export SSL_CERT_FILE=''${SSL_CERT_FILE:-$trust_bundle}
                if [[ -f $estate ]]; then
                  router_addr=$(yq -r '.north-york.hosts.opnsense.addresses.lan // ""' "$estate")
                  router_fqdn=$(yq -r '.north-york.hosts.opnsense.fqdn // ""' "$estate")
                  nas_addr=$(yq -r '.north-york.hosts.nas.addresses.lan // ""' "$estate")
                  nas_fqdn=$(yq -r '.north-york.hosts.nas.fqdn // ""' "$estate")
                  ca_addr=$(yq -r '.north-york.hosts.nas.vms.step-ca.addresses.lan // ""' "$estate")
                  ca_fqdn=$(yq -r '.north-york.hosts.nas.vms.step-ca.services."private-ca".url // ""' "$estate" \
                    | sed -e 's|^https://||' -e 's|/$||')
                  if [[ -z ''${DNS_SERVER:-} && -n $router_addr ]]; then export DNS_SERVER=$router_addr; fi
                  if [[ -z ''${DNS_NAS_FQDN:-} && -n $nas_fqdn ]]; then export DNS_NAS_FQDN=$nas_fqdn; fi
                  if [[ -z ''${DNS_NAS_ADDRESS:-} && -n $nas_addr ]]; then export DNS_NAS_ADDRESS=$nas_addr; fi
                  if [[ -z ''${DNS_ROUTER_FQDN:-} && -n $router_fqdn ]]; then export DNS_ROUTER_FQDN=$router_fqdn; fi
                  if [[ -z ''${DNS_ROUTER_ADDRESS:-} && -n $router_addr ]]; then export DNS_ROUTER_ADDRESS=$router_addr; fi
                  if [[ -z ''${DNS_CA_FQDN:-} && -n $ca_fqdn ]]; then export DNS_CA_FQDN=$ca_fqdn; fi
                  if [[ -z ''${DNS_CA_ADDRESS:-} && -n $ca_addr ]]; then export DNS_CA_ADDRESS=$ca_addr; fi
                  if [[ -z ''${DNS_VERIFY:-} && -n $DNS_SERVER && -n $DNS_NAS_FQDN && -n $DNS_ROUTER_FQDN && -n $DNS_CA_FQDN ]]; then export DNS_VERIFY=1; fi
                  if [[ -z ''${HTTPS_URL:-} && -n $router_fqdn ]]; then export HTTPS_URL=https://$router_fqdn/; fi
                  if [[ -z ''${HTTPS_VERIFY:-} && -n $HTTPS_URL ]]; then export HTTPS_VERIFY=1; fi
                fi
                # Make-based verification supplies the checkout so new, untracked
                # probe files run before their first commit. Direct `nix run` uses
                # the immutable flake source instead.
                test_root=''${HOMELAB_ROOT:-${self}}
                if (( $# == 0 )); then
                  # Every probe file under tests/verify runs by default; new
                  # .bats files are registered automatically.
                  set -- "$test_root"/tests/verify/*.bats
                fi
                if [[ $preflight == true ]]; then
                  for test_file in "$@"; do
                    if [[ ! -f $test_file ]]; then
                      printf 'Activation verification needs explicit test files, not Bats options: %s\n' "$test_file" >&2
                      exit 1
                    fi
                    case "$test_file" in
                      "$test_root"/tests/verify/*.bats) ;;
                      *) printf 'Activation verification accepts probe files under tests/verify only: %s\n' "$test_file" >&2; exit 1 ;;
                    esac
                    case "$test_file" in
                      */nas.bats)
                        # shellcheck source=/dev/null
                        source "$test_root"/tests/verify/lib/nas-samba-safety.sh
                        require_smb_tools
                        ;;
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
