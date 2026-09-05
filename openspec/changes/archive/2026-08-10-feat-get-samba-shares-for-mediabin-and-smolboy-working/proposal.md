## Why

The NAS already imports two ZFS pools (`mediaBin`, `smolBoy`) that hold the
user's media and personal data, but nothing on the network can reach them.
We want the pools available to macOS and Linux clients over SMB — guest-open,
discoverable in Finder via mDNS, so `smb://NASty.local` "just works."

## What Changes

- Add a new `hosts/nas/samba.nix` role module enabling `services.samba`.
- Expose two guest-open shares:
  - `mediaBin` → `path = /mediaBin/data/media` (Books/Movies/Music/Shows)
  - `smolBoy` → `path = /smolBoy/data` (aiModels/backups/kpvc/youtube)
- Guest connections forced to `operator` (`force user` / group) so guest
  read-write actually honors the operator-owned dataset permissions.
- Advertise SMB over mDNS via Samba's built-in `mdns name = mdns` so macOS/
  Linux clients discover the server at `smb://NASty.local`.
- Enable Samba's `fruit` + `streams_xattr` VFS modules for correct macOS
  Finder metadata handling (Resource Forks, timestamps).
- Open firewall TCP ports `139` and `445` for SMB.
- Wire `./samba.nix` into `hosts/nas/default.nix`.
- No `smolBoy` pool-root exposure of `truenas_users` beyond filesystem perms;
  guest access is limited by existing directory permissions.

## Planes

### Behavioral truth
- `behavior.storage.nas-samba`: the NAS exposes guest-open, mDNS-discoverable
  SMB shares `mediaBin` and `smolBoy`, reachable at `smb://NASty.local`. (new)

No other plane is touched: enabling `services.samba` is an ops selection, but
this repo's established convention treats "the box provides X" as behavioral
truth (cf. `behavior.storage.nas-utility-packages`, `nas-boot`), and ops is
deliberately scoped to deployment/tooling. The module-composition rule and
firewall pattern already live in `architecture.host-modules`, which this change
conforms to without altering.

## Spec pairs

- `behavior.storage.nas-samba` -> paired enforcement via a `nix eval` structure
  check (automated) plus a live `smbutil view -N -G //10.10.10.11` wire check
  (automated, run on the macOS deployer where openspec runs).

## Impact

- **Code**: new `hosts/nas/samba.nix` (NixOS module); one-line import added to
  `hosts/nas/default.nix`.
- **Firewall**: opens TCP `139`/`445` on the NAS (currently only `22`).
- **Runtime**: enables the `samba` service and its dependencies on the NAS.
- **Network**: `mediaBin` and `smolBoy` become writable-by-guest SMB shares on
  the homelab LAN.
- **Not changed**: ZFS pools/datasets, `zfs.nix`, flake, deployment tooling.