{
  sites.home = { };

  hosts.nas.site = "home";

  workloads.file-sharing = {
    placements = [ "nas" ];
    state = [ "mediaBin" "smolBoy" ];
  };

  states = {
    mediaBin.owners = [ "nas" ];
    smolBoy.owners = [ "nas" ];
  };
}
