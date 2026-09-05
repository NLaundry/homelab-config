{ config, lib, pkgs, ... }:

let
  # Keep ZFS working by choosing a compatible kernel.
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in
{
  boot.kernelPackages = latestKernelPackage;

  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "007f0200";

  # Import existing pools without creating or replacing data.
  boot.zfs.extraPools = [ "smolBoy" "mediaBin" ];

  # Avoid taking a root pool that another host may still use.
  boot.zfs.forceImportRoot = false;
}
