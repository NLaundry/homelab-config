---
id: estate.nas-storage
---

## Purpose

The Estate inventory records where file sharing and its storage pools are located so an operator can find them without evaluating generated topology code.

## MODIFIED Requirements

### Requirement: The NAS hosts file sharing
**ID:** `smb-workload-placement`
The Estate inventory SHALL record the internal file-sharing service on the NAS host.

#### Scenario: File-sharing location is inspected
**ID:** `file-sharing-placement-resolves`
- **WHEN** an operator reads the file-sharing service entry
- **THEN** its host is `nas`

### Requirement: The NAS holds the storage pools
**ID:** `zfs-pool-placement`
The Estate inventory SHALL record `mediaBin` and `smolBoy` as storage pools on the NAS host.

#### Scenario: Pool location is inspected
**ID:** `pool-ownership-resolves`
- **WHEN** an operator reads the NAS host entry
- **THEN** its storage details list `mediaBin` and `smolBoy`
