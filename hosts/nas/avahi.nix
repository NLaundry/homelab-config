{ config, lib, pkgs, ... }:

{
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      # Publish the address so clients can find the server by its .local name.
      addresses = true;
      domain = true;
    };
    # Let the NAS find other devices by their .local names.
    nssmdns4 = true;
    # Avoid exposing device names to other networks.
    reflector = false;

    # Announce the shares here so Finder can find them.
    extraServiceFiles.smb = ''
      <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
      <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
      <service-group>
        <name replace-wildcards="yes">%h</name>
        <service>
          <type>_smb._tcp</type>
          <port>445</port>
        </service>
      </service-group>
    '';
  };
}
