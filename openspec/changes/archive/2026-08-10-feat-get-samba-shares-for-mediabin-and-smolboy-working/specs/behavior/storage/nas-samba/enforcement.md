# Enforcement: The NAS exposes guest-open, mDNS-discoverable SMB shares

Paired with `spec.md` (`behavior.storage.nas-samba`). Two deterministic
`nix eval` structure checks (mirroring the existing
`behavior.storage.nas-utility-packages` pattern) prove the Samba config and
firewall are declared; a native macOS `smbutil view` proves a guest can
actually list the shares over the wire; the genuinely non-deterministic
runtime residue (mDNS resolution + actual guest writes) rides the
`behavioural` review lens.

```yaml
version: 1
spec: behavior.storage.nas-samba
bindings:
  - id: samba-config-eval
    covers: [samba-shares-exposed, shares-declared, guest-force-operator, smb-multicast-discovery]
    mechanism: command
    strength: automated
    status: active
    targets:
      - hosts/nas/samba.nix
    run:
      command: nix
      args:
        - eval
        - --json
        - .#nixosConfigurations.nas.config.services.samba.settings
      cwd: .
    limitations: Confirms the shares, paths, guest options, force-operator mapping, and mdns flag in the evaluated flake; it does not prove the shares work over the network or that mDNS is actually broadcasting. Targets services.samba.settings (not the whole services.samba attrset) because nixos-26.05 migrated Samba to the RFC0042 structured settings API and the legacy shares/configText/extraConfig options are removed-option stubs that throw when the whole attrset is forced to JSON.

  - id: samba-firewall-eval
    covers: [smb-ports-open, smb-ports-open-scenario]
    mechanism: command
    strength: automated
    status: active
    targets:
      - hosts/nas/default.nix
    run:
      command: nix
      args:
        - eval
        - --json
        - .#nixosConfigurations.nas.config.networking.firewall.allowedTCPPorts
      cwd: .
    limitations: Confirms ports 139 and 445 are in the evaluated firewall config, not that the network delivers them.

  - id: smbutil-view-wire
    covers: [guest-access, samba-shares-exposed]
    mechanism: command
    strength: automated
    status: active
    targets:
      - hosts/nas/samba.nix
    run:
      command: smbutil
      args: [view, -N, -G, //10.10.10.11]
      cwd: .
    limitations: Proves an anonymous guest session can list the share names (mediaBin, smolBoy) against a reachable NAS; it does not traverse into directories, resolve mDNS, or verify writes. Fails only meaningfully when the NAS is up; an unreachable NAS is an environment condition to treat as a skip, not a config regression.

  - id: samba-runtime-review
    covers: [discoverable-at-nastylocal, guest-write-operator]
    mechanism: review
    strength: review
    status: active
    targets:
      - hosts/nas/samba.nix
    review:
      procedure: From the macOS deployer (or a Linux client), confirm (a) the share appears in Finder / `dns-sd -B _smb._tcp local.` under the name `NASty` and connects at `smb://NASty.local`, and (b) a guest connection writing a file into an operator-owned mediaBin/smolBoy directory succeeds.
      inputs:
        - hosts/nas/samba.nix
        - design.md
    limitations: Depends on a live client on the LAN; a `nix eval` cannot prove mDNS advertising or runtime write success, so this residue is reviewed rather than automated.