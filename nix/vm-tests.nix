{ lib, pkgs, vmHarness, nasVm }:

let
  registry = {
    vm-harness-private-network = {
      derivation = vmHarness;
      aggregateName = "harness-private-network";
      source = "tests/harness/nixos-vm.nix";
      disposable = true;
      nonActivating = true;
      privateNetwork = true;
    };
    nas-samba-vm = {
      derivation = nasVm;
      aggregateName = "nas-samba-behavior";
      source = "tests/nas-vm.nix";
      disposable = true;
      nonActivating = true;
      privateNetwork = true;
    };
  };

  publicRegistry = lib.mapAttrs (_: item:
    builtins.removeAttrs item [ "derivation" ]) registry;

  leafChecks = lib.mapAttrs (_: item: item.derivation) registry;

  aggregate = (pkgs.linkFarm "homelab-vm-tests" (lib.mapAttrsToList (_: item: {
    name = item.aggregateName;
    path = item.derivation;
  }) registry)).overrideAttrs (old: {
    passthru = (old.passthru or { }) // {
      inherit publicRegistry;
      leafDrvPaths = lib.mapAttrs (_: item: item.derivation.drvPath) registry;
    };
  });
in
{
  inherit publicRegistry;
  checks = leafChecks // { vm-tests = aggregate; };
}
