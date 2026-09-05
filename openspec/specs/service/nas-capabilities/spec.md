---
id: service.nas-capabilities
---

## Purpose

The NAS provides stable file-sharing and administrator-access capabilities independently of the products, settings, and physical placement that realize them.

## Requirements

### Requirement: Clients can use the declared file shares
**ID:** `samba-shares-exposed`
The file-sharing service SHALL allow an unauthenticated internal client to enumerate and mount the `mediaBin` and `smolBoy` shares without credentials.

#### Scenario: Guest discovers and mounts a share
**ID:** `guest-discovers-share`
- **WHEN** an internal guest client enumerates the file-sharing endpoint and mounts either declared share
- **THEN** the client sees both declared share names and completes the mount without credentials

### Requirement: Guest writes have bounded file semantics
**ID:** `guest-force-operator`
The file-sharing service SHALL allow a guest client to create, read, and remove its own uniquely scoped fixture within each writable declared share.

#### Scenario: Guest completes a file round trip
**ID:** `guest-file-round-trip`
- **WHEN** a guest writes a unique fixture to either declared writable share
- **THEN** the client reads the original content, removes the fixture, and observes no residue from its run

### Requirement: Authorized operators can administer the NAS
**ID:** `operator-access`
The NAS administration service SHALL allow an authorized operator to authenticate over SSH with an approved key and obtain non-interactive root privileges.

#### Scenario: Authorized operator elevates
**ID:** `authorized-operator-elevates`
- **WHEN** an authorized operator connects over SSH and requests non-interactive elevation
- **THEN** authentication and elevation succeed without a password prompt

#### Scenario: Authentication cannot be established
**ID:** `operator-authentication-fails-closed`
- **WHEN** the administration probe cannot establish approved-key authentication
- **THEN** it reports that operator access was not established rather than treating transport failure as an authorization result
