{ lib }:

let
  inherit (lib) mkOption types;
  safeReference = types.str;
in
{ ... }:
{
  options.estate = {
    sites = mkOption {
      type = types.attrsOf (types.submodule ({ ... }: { options = { }; }));
      default = { };
      description = "Logical Estate sites keyed by stable identity.";
    };

    hosts = mkOption {
      type = types.attrsOf (types.submodule ({ ... }: {
        options.site = mkOption {
          type = safeReference;
          description = "Logical site containing this host role.";
        };
      }));
      default = { };
      description = "Logical managed host roles.";
    };

    workloads = mkOption {
      type = types.attrsOf (types.submodule ({ ... }: {
        options = {
          placements = mkOption {
            type = types.listOf safeReference;
            default = [ ];
            description = "Authoritative logical host placements.";
          };
          state = mkOption {
            type = types.listOf safeReference;
            default = [ ];
            description = "Durable state dependencies.";
          };
        };
      }));
      default = { };
      description = "Managed logical workloads.";
    };

    states = mkOption {
      type = types.attrsOf (types.submodule ({ ... }: {
        options.owners = mkOption {
          type = types.listOf safeReference;
          default = [ ];
          description = "Authoritative logical host owners.";
        };
      }));
      default = { };
      description = "Managed durable state nodes.";
    };
  };
}
