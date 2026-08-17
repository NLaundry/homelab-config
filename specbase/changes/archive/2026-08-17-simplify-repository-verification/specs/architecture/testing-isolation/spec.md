---
id: architecture.testing-isolation
---

## Purpose

Disposable system tests use their execution host only as compute and keep candidate guests off the physical homelab network.

## MODIFIED Requirements

### Requirement: The test subject is isolated from its compute provider
**ID:** `test-subject-boundary`
Every NixOS integration test SHALL run candidate systems exclusively as ephemeral guests rather than activating a candidate on the selected execution host.

#### Scenario: The physical NAS supplies VM compute
**ID:** `builder-remains-compute-only`
- **WHEN** the physical NAS executes the aggregate VM suite
- **THEN** every candidate runs in disposable guests and the NAS does not activate it as its own generation

### Requirement: Test networks are isolated from the physical LAN
**ID:** `test-network-boundary`
Every NixOS integration guest SHALL communicate only through explicitly declared private virtual test networks and SHALL NOT receive an implicit interface, default route, or route to the physical homelab LAN.

#### Scenario: Samba test guests communicate
**ID:** `guests-use-private-test-network`
- **WHEN** the Samba client and server communicate
- **THEN** each has only its declared private test interface and neither can route to the physical LAN
