{ config, lib, pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 139 445 ];

  services.samba = {
    enable = true;

    settings = {
      global = {
        security = "user";

        # Allow unknown users to connect as guests without a password.
        "map to guest" = "Bad User";

        # Avoid redirects so clients can connect using the server's address.
        "host msdfs" = "no";

        # Keep extra Mac file information with each file.
        "vfs objects" = "fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:posix_rename" = "no";
        "fruit:veto_appledouble" = "no";
        "fruit:delete_empty_adfiles" = "yes";
      };

      # Keep unrelated data private by sharing only the media folder.
      mediaBin = {
        path = "/mediaBin/data/media";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        # Use the file owner's account so guests can write existing data.
        "force user" = "operator";
        "force group" = "users";
      };

      # Share only data folders to keep system folders out of view.
      smolBoy = {
        path = "/smolBoy/data";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "force user" = "operator";
        "force group" = "users";
      };
    };
  };
}
