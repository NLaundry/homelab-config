{ config, lib, pkgs, ... }:

let
  # Pick the newest kernel that still ships a non-broken ZFS module, so ZFS
  # never blocks on a too-new kernel (the 6.18-vs-ZFS trap).
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
  # Note: this might jump back and forth as kernels are added or removed upstream.
  boot.kernelPackages = latestKernelPackage;

  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "007f0200";

  # Data pools already exist on disk — import only, NEVER create.
  boot.zfs.extraPools = [ "smolBoy" "mediaBin" ];

  # Safer default (becomes the default in 26.11); also silences the eval warning.
  boot.zfs.forceImportRoot = false;
}
