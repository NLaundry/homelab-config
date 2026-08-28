---
id: estate.nas-storage
---

## Purpose

The estate keeps current file-sharing workload placement and durable storage ownership explicit so host replacement and consolidation cannot silently move responsibility.

## MODIFIED Requirements

### Requirement: The NAS role owns the file-sharing workload
**ID:** `smb-workload-placement`
The estate SHALL assign the internal file-sharing workload to the NAS role.

#### Scenario: Workload placement is inspected
**ID:** `file-sharing-placement-resolves`
- **WHEN** the declared estate placement for the file-sharing workload is inspected
- **THEN** it resolves to exactly the NAS role

### Requirement: The NAS role owns the declared storage pools
**ID:** `zfs-pool-placement`
The estate SHALL assign authoritative ownership of the `mediaBin` and `smolBoy` storage pools to the NAS role.

#### Scenario: Pool ownership is inspected
**ID:** `pool-ownership-resolves`
- **WHEN** the declared estate owner of either storage pool is inspected
- **THEN** it resolves to the NAS role and no second authoritative owner is declared
