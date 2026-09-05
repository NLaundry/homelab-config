---
id: configuration.opnsense-netbird
---

## Purpose

OPNsense realizes a bounded NetBird peer using the supported official plugin while retaining explicit control of router interfaces and persistent firewall configuration.

## ADDED Requirements

### Requirement: NetBird plugin compatibility is required
**ID:** `opnsense-netbird-plugin-supported`
North York OPNsense SHALL enable only an official NetBird plugin and API surface confirmed compatible with its installed firmware.

#### Scenario: Required compatibility is absent
**ID:** `unsupported-router-is-not-mutated`
- **WHEN** the installed firmware, package, or required API fails compatibility preflight
- **THEN** NetBird plugin configuration stops before mutating the router

### Requirement: NetBird peer settings are bounded
**ID:** `opnsense-netbird-peer-bounded`
North York OPNsense SHALL run its NetBird peer with overlay DNS, NetBird SSH, SFTP, and SSH port forwarding disabled until separately proposed.

#### Scenario: Peer configuration is inspected
**ID:** `optional-peer-services-remain-disabled`
- **WHEN** the managed plugin settings are read
- **THEN** the peer is enabled without taking over DNS or exposing NetBird SSH capabilities

### Requirement: NetBird interface is assigned
**ID:** `opnsense-wt0-assigned`
North York OPNsense SHALL assign the NetBird `wt0` device as a managed interface without granting routed LAN access in this prefix.

#### Scenario: Enrolled router interfaces are inspected
**ID:** `wt0-routing-boundary`
- **WHEN** the enrolled router's interface and firewall configuration is read
- **THEN** `wt0` is assigned and no active rule permits overlay traffic to the North York LAN
