---
id: behavior.storage.nas-samba
---

## Purpose
The NAS holds the user's media and personal data on two ZFS pools
(`mediaBin`, `smolBoy`) but exposes nothing to the LAN. This pair governs
guest-open, mDNS-discoverable SMB access to both pools so macOS and Linux
clients can browse them without credentials at `smb://NASty.local`.

### Requirement: The NAS exposes guest-open SMB shares for mediaBin and smolBoy
**ID:** `samba-shares-exposed`
The NAS configuration SHALL enable the Samba service and define two SMB
shares: `mediaBin` served from `/mediaBin/data/media` and `smolBoy` served
from `/smolBoy/data`. Both SHALL accept guest (unauthenticated) connections
so that clients on the homelab LAN can browse the pools without credentials.

#### Scenario: mediaBin and smolBoy shares are declared
**ID:** `shares-declared`
- **WHEN** the `nas` configuration is evaluated
- **THEN** `services.samba.enable` is `true`
- **AND** `services.samba.shares` declares a `mediaBin` share pointing at
  `/mediaBin/data/media`
- **AND** `services.samba.shares` declares an `smolBoy` share pointing at
  `/smolBoy/data`

#### Scenario: guest connections are accepted
**ID:** `guest-access`
- **WHEN** a client connects to either share without credentials
- **THEN** it is treated as a guest and can browse the share's directories

### Requirement: Guest file operations run as operator so writes honor dataset permissions
**ID:** `guest-force-operator`
The share configuration SHALL force SMB file operations (`force user` /
`force group`) to run as the `operator` user (uid 1000) and its primary
group, so that guest read-write actually takes effect against the
operator-owned datasets on the pools rather than mapping to a non-writable
unprivileged user.

#### Scenario: guest writes succeed against operator-owned data
**ID:** `guest-write-operator`
- **WHEN** a guest connection writes a file into a mediaBin or smolBoy
  dataset directory owned by `operator`
- **THEN** the write succeeds (the operation executes with `operator`'s
  filesystem identity)

### Requirement: The NAS advertises SMB over mDNS for automatic discovery
**ID:** `smb-multicast-discovery`
The NAS configuration SHALL advertise SMB shares via mDNS so that macOS and
Linux clients can discover and reach the server at `smb://NASty.local`
without knowing the IP address.

#### Scenario: the server is discoverable at NASty.local
**ID:** `discoverable-at-nastylocal`
- **WHEN** the Samba server is running with mDNS advertising enabled
- **THEN** the server responds to an `_smb._tcp` mDNS query for `NASty`
  and is reachable at `NASty.local`

### Requirement: The firewall allows SMB traffic
**ID:** `smb-ports-open`
The NAS firewall SHALL permit inbound SMB, specifically TCP ports `139` and
`445`, so that LAN clients can reach the shares.

#### Scenario: SMB ports are open
**ID:** `smb-ports-open-scenario`
- **WHEN** the `nas` firewall is evaluated
- **THEN** TCP ports `139` and `445` are present in the allowed inbound ports
