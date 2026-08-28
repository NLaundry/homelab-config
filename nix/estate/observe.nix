{ lib, nasConfiguration }:

{
  hosts.nas = {
    workloads = lib.optional nasConfiguration.config.services.samba.enable "file-sharing";
    state = nasConfiguration.config.boot.zfs.extraPools;
  };
}
