# Avahi mDNS/Bonjour publishing for the NAS so macOS Finder / Linux clients
# discover the SMB server at smb://NASty.local.
#
# Why this exists (reverses design D3): Samba's `mdns name = mdns` does NOT
# publish Bonjour records for a standalone file server — its mDNS responder
# lives in the AD-DC `samba` daemon, which we don't run, and this nixpkgs
# Samba build isn't even compiled with avahi/dns_sd support (`smbd -b` shows
# no mDNS feature, and `smbd` doesn't link an mDNS library). The only way to
# advertise `_smb._tcp` over mDNS is a real mDNS daemon, so Avahi publishes a
# `_smb._tcp` service record for port 445 under the host name (NASty →
# NASty.local).
#
# Behavioral truth: specbase `behavior.storage.nas-samba` (smb-multicast-discovery).
{ config, lib, pkgs, ... }:

{
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      # Publish the host's A/AAAA records so NASty.local resolves on clients.
      addresses = true;
      # Announce the local domain so clients browse the right domain.
      domain = true;
    };
    # Resolve .local names on the NAS itself.
    nssmdns = true;
    # Reflector not needed on a flat single-LAN homelab.
    reflector = false;

    # Publish the SMB service so Finder discovers the server. Avahi does not
    # auto-reflect services.samba; it needs an explicit service file. `%h`
    # expands to the hostname (NASty), giving NASty.local.
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
