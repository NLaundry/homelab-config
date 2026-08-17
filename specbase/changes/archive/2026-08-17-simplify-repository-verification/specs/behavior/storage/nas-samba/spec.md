---
id: behavior.storage.nas-samba
---

## Purpose

The NAS gives homelab clients simple credential-free access to the two intended data shares and preserves guest read/write behavior.

## MODIFIED Requirements

### Requirement: The NAS exposes guest-open SMB shares for mediaBin and smolBoy
**ID:** `samba-shares-exposed`
The NAS SHALL expose SMB shares named `mediaBin` and `smolBoy` to homelab clients. A guest client SHALL be able to enumerate, mount, and list both shares without supplying credentials.

#### Scenario: A guest browses the NAS
**ID:** `shares-declared`
- **WHEN** a guest client enumerates and mounts the NAS SMB service
- **THEN** `mediaBin` and `smolBoy` are both present and listable

#### Scenario: Guest connections are accepted
**ID:** `guest-access`
- **WHEN** a client mounts either advertised share without credentials
- **THEN** the mount succeeds and the client can list its available directories

### Requirement: Guest clients can modify writable share state
**ID:** `guest-force-operator`
A guest SMB client SHALL be able to create, read, and remove a uniquely named file within a writable location on each ordinary share.

#### Scenario: A guest completes a bounded file round trip
**ID:** `guest-write-operator`
- **WHEN** a guest creates uniquely named content on `mediaBin` or `smolBoy`
- **THEN** the same client reads the content and removes its exact fixture cleanly

## REMOVED Requirements

### Requirement: The NAS advertises SMB over mDNS for automatic discovery
**ID:** `smb-multicast-discovery`
**Reason:** Default verification and the selected user workflow address the inventory NAS endpoint directly; mDNS is not part of the retained success contract.
**Migration:** Avahi configuration may remain, but no dedicated behavioral requirement or test is maintained.

### Requirement: The firewall allows SMB traffic
**ID:** `smb-ports-open`
**Reason:** Successful guest enumeration and mounts already prove the externally meaningful reachability outcome; an exact firewall-port list is operational mechanism rather than separate behavior.
**Migration:** Preserve the production firewall configuration while relying on direct client behavior as evidence.
