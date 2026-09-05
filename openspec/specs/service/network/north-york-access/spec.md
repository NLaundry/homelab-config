---
id: service.network.north-york-access
---

## Purpose

North York private resources are reachable through the overlay only by explicitly authorized peers.

## Requirements

### Requirement: Authorized administrators reach North York resources
**ID:** `authorized-north-york-access`
An authorized administrator peer SHALL be able to initiate supported network traffic to the selected North York LAN resources through NetBird.

#### Scenario: Administrator reaches a clientless LAN host
**ID:** `administrator-reaches-north-york-host`
- **WHEN** an administrator peer initiates a bounded probe to a selected North York LAN address
- **THEN** the probe reaches that address through the North York routing boundary

### Requirement: Unauthorized peers cannot reach North York resources
**ID:** `unauthorized-north-york-access-denied`
A peer outside the authorized administrator source group SHALL be unable to initiate traffic to the North York LAN resource through NetBird.

#### Scenario: Non-administrator probes North York
**ID:** `non-administrator-is-denied`
- **WHEN** a connected peer outside the administrator source group probes a selected North York LAN address
- **THEN** the overlay does not deliver the probe to that resource
