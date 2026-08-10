## Context

The NAS (`NASty`, 10.10.10.11) is a NixOS host managed by flakes under
`hosts/nas/`. It imports two ZFS pools holding existing user data:

```
mediaBin  /mediaBin/data/media/{Books,Movies,Music,Shows}   (owner: operator)
smolBoy   /smolBoy/data/{aiModels,backups,kpvc,youtube,...} (owner: operator)
```

There are no network shares today; the firewall only opens SSH (`22`). The
pools were previously hosted on a TrueNAS-style system, evidenced by inert
`mediaBin/.system/*` datasets with `mountpoint=legacy` that are not mounted on
this NixOS install (so they never appear under `/mediaBin`).

Clients are the user's own macOS and Linux machines on the homelab LAN. The
goal is convenient, passwordless access from Finder / file managers.

## Goals / Non-Goals

**Goals:**
- Guest-open SMB access to the media and personal-data pools.
- Automatic discovery in macOS Finder via mDNS (`smb://NASty.local`).
- Guest read-write that actually works against operator-owned datasets.
- Correct macOS Finder behavior (metadata, timestamps).
- Minimal runtime surface (avoid extra discovery daemons).

**Non-Goals:**
- Per-user SMB accounts, ACLs, quotas, or share-level per-subtree security.
- TLS/encryption, WAN exposure, or beyond-LAN access.
- Migration of the legacy `.system` datasets (left untouched).
- Any change to the `smolBoy`/`mediaBin` pool topology or mount strategy (D5).

## Decisions

**D1 — One share per pool, path set one rung below the root.**
Shares point at `/mediaBin/data/media` and `/smolBoy/data`, not the literal
pool roots. Datasets mount as directories, so each single share exposes every
sub-dataset as a browsable folder — no separate share per dataset. Pinning one
rung down gives Finder a clean top level (`Books/…`, `aiModels/…`) instead of
a `data/media/…` nest. Rationale follows the pool's real layout (thin root
wrappers), discovered from `zfs list` on the box.

**D2 — Guest-open, forced to `operator`.**
Guest connections map to a non-writable unprivileged user by default, which
would silently make guest-*write* a no-op against the `operator`-owned 755
datasets. Setting `force user = operator` (+ primary group) on both shares
makes every SMB operation execute with `operator`'s filesystem identity, so
guest read-write genuinely holds. Trade-off: all writes are attributed to one
user — acceptable for a single-operator homelab.

**D3 — Samba built-in mDNS (`mdns name = mdns`), not avahi.**
Chosen to keep the runtime minimal — no extra discovery daemon. Modern Samba
advertises `_smb._tcp` itself, which is all macOS needs to resolve
`smb://NASty.local`; Linux clients resolve mDNS on their own side. Avahi would
only be worth the additional dependency if the NAS later advertises *other*
services (SSH, printer, UPnP). Known minor risk: Samba's built-in mDNS has
occasional broadcast flakiness with macOS (share not showing until Finder
refreshes); acceptable and easy to switch to avahi later if it bites.

**D4 — `fruit` + `streams_xattr` VFS modules.**
Enables Apple's SMB protocol extensions so Finder handles Resource Forks,
accurate timestamps, and `.AppleDouble` metadata correctly. No-op for Linux
clients.

**D5 — Firewall expands to SMB ports.**
Add TCP `139` and `445` to `allowedTCPPorts` alongside the existing `22`.

**Enforcement mechanism split:**
- A `nix eval` (automated `command` binding, matching the existing
  `behavior.storage.nas-utility-packages` pattern) protects the *structural*
  claims: shares declared with the right `path`, guest options, force-operator
  mapping, mDNS flag, and firewall ports. High leverage — one evaluation
  covers the whole family.
- A live `smbutil view -N -G //10.10.10.11` shell-out (automated `command`
  binding) protects the *wire-visible* claim: that a guest can actually list
  the shares, proving anonymous auth `and` share exposure from a real client.
  `smbutil view` with `-G` (guest) and `-N` (no password prompt) is native on
  macOS, which is the machine openspec runs on (the deployer). This is an
  honest end-to-end check rather than a review placeholder because guest-open
  + macOS tooling make it deterministic and credential-free.
- The `force user` + `fruit`/Finder behaviors are closest to runtime truth;
  where not directly observable via the structure eval, they ride the review
  lens (`behavioural`) as the honest residue above the deterministic gate.

## Risks / Trade-offs

- [Samba built-in mDNS flakiness with macOS] -> Acceptable; switch to avahi
  (single config flip) if Finder discovery is unreliable.
- [Guest-open RW exposes write to any LAN client] -> Acceptable for a trusted
  homelab LAN; can tighten to guest read-only or add auth later without
  reworking share structure.
- [smbutil binding fails when NAS is unreachable during validate] -> Binding is
  `active` but expected to run only on the deployer with the NAS up; a
  not-running NAS is an environment condition, not a config regression, and is
  treatable as a skip rather than a hard block.
- [Boot ordering: smbd may start before pools mount] -> ZFS import runs at the
  `zfs.target` stage ahead of `smbd` at `multi-user.target`; add a systemd
  `samba` ordering note so this never regresses.
- [`.system` legacy datasets] -> Not mounted under `/mediaBin`; verified inert
  and out of scope.

## Migration Plan

1. Add `hosts/nas/samba.nix` defining the two shares, guest/force-user options,
   mDNS flag, VFS modules, and firewall ports.
2. Import `./samba.nix` from `hosts/nas/default.nix` (conforms to the existing
   `architecture.host-modules` rule).
3. Deploy with `make test` first (reverts on reboot), then `make deploy` to set
   as boot default. Deploy runs build-on-NAS via the Makefile.
4. Reverse the change by removing the import and share module then redeploying.