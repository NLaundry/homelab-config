{ pkgs, ... }:

let
  verificationRoot = "/var/lib/homelab-verification/smb";
  verificationRuns = "${verificationRoot}/runs";
in
{
  users.groups.verification = {
    gid = 980;
  };

  users.users.tester = {
    uid = 980;
    isSystemUser = true;
    group = "verification";
    description = "Constrained live-verification principal";
    shell = pkgs.shadow;
    createHome = false;
    hashedPassword = "!";
    extraGroups = [ ];
    openssh.authorizedKeys.keys = [ ];
  };

  # A small tmpfs gives verification writes independent byte and inode ceilings
  # without consuming either ordinary ZFS pool. The tester can create direct
  # children beneath runs but cannot replace or change root metadata.
  fileSystems.${verificationRoot} = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "nodev"
      "noexec"
      "nosuid"
      "size=64M"
      "nr_inodes=4096"
      "mode=0750"
      "uid=0"
      "gid=980"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/homelab-verification 0750 operator verification -"
  ];

  # Mount units start after the ordinary tmpfiles pass. Initialize ownership and
  # the fixed run-child layout after the tmpfs exists and before Samba accepts
  # connections.
  systemd.services.homelab-verification-state = {
    description = "Initialize bounded live-verification state";
    wantedBy = [ "multi-user.target" ];
    requiredBy = [ "samba-smbd.service" ];
    before = [ "samba-smbd.service" ];
    after = [ "var-lib-homelab\\x2dverification-smb.mount" ];
    requires = [ "var-lib-homelab\\x2dverification-smb.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.coreutils}/bin/install -d -o operator -g verification -m 0750 ${verificationRoot}
      ${pkgs.coreutils}/bin/install -d -o operator -g verification -m 0730 ${verificationRuns}
    '';
  };

  services.samba.settings = {
    mediaBin."invalid users" = "tester";
    smolBoy."invalid users" = "tester";

    "homelab-verification$" = {
      path = verificationRuns;
      browseable = "no";
      "read only" = "no";
      "guest ok" = "no";
      "valid users" = "tester";
      "follow symlinks" = "no";
      "wide links" = "no";
      "vfs objects" = "full_audit fruit streams_xattr";
      "full_audit:prefix" = "%u|%I|homelab-verification$";
      "full_audit:success" = "mkdirat create_file openat write pwrite renameat unlinkat";
      "full_audit:failure" = "none";
      "full_audit:facility" = "LOCAL5";
      "full_audit:priority" = "NOTICE";
      "full_audit:syslog" = "true";
    };
  };
}
