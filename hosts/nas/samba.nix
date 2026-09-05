# Guest-open, mDNS-discoverable SMB shares for the mediaBin and smolBoy ZFS
# pools. See openspec/specs/service/nas-capabilities/spec.md.
#
# Both pools are owner by `operator` (uid 1000); guest connections are forced
# to operator's filesystem identity so guest read-write actually holds against
# the operator-owned datasets. Samba advertises SMB itself over mDNS, so no
# avahi/nmbd discovery daemon is needed for macOS Finder / Linux clients to
# reach the server at smb://NASty.local.
{ config, lib, pkgs, ... }:

{
  services.samba = {
    enable = true;

    settings = {
      # --- global ---------------------------------------------------------
      global = {
        security = "user";

        # Let unauthenticated clients fall through to the guest account so the
        # shares can be browsed without credentials.
        "map to guest" = "Bad User";

        # mDNS/Bonjour discovery of the server (smb://NASty.local) is published
        # by Avahi, not Samba — see ./avahi.nix. Samba's `mdns name = mdns` only
        # responds in the AD-DC `samba` daemon (not run here) and this nixpkgs
        # build has no mDNS support compiled in, so it is omitted.

        # macOS clients address shares as \\10.10.10.11\share, which Samba's DFS
        # referral parser rejects with `parse_dfs_path_strict: can't parse
        # hostname` and then fails the tree connect with "share does not exist".
        # We are not a DFS host, so disable DFS host resolution and serve shares
        # directly. (No share here is marked `msdfs root = yes`.)
        "host msdfs" = "no";

        # Apple SMB extensions for correct Finder metadata/timestamp handling
        # (Resource Forks, .AppleDouble). Applied globally so both shares
        # inherit them; no-op for Linux clients.
        "vfs objects" = "fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:posix_rename" = "no";
        "fruit:veto_appledouble" = "no";
        "fruit:delete_empty_adfiles" = "yes";
      };

      # --- mediaBin ------------------------------------------------------
      # One rung below the pool root: datasets mount as directories, so a single
      # share exposes Books/Movies/Music/Shows as a clean Finder top level.
      mediaBin = {
        path = "/mediaBin/data/media";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        # Force every guest op to run as operator so guest read-write honors
        # the operator-owned datasets instead of mapping to a non-writable
        # unprivileged user. operator's primary group is `users` (gid 100) —
        # there is no group named `operator`, so force group must be `users`.
        "force user" = "operator";
        "force group" = "users";
      };

      # --- smolBoy -------------------------------------------------------
      # Exposes /smolBoy/data/{aiModels,backups,kpvc,youtube,...}; the smolBoy
      # pool root (and the inert truenas_users dataset) is not exposed beyond
      # existing filesystem permissions.
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
