---
id: configuration.opnsense-netbird
---

## Purpose

OPNsense realizes a bounded NetBird peer through the supported official plugin without enabling routed LAN access.

## ADDED Requirements

### Requirement: NetBird plugin compatibility is required
**ID:** `opnsense-netbird-plugin-supported`
North York OPNsense SHALL use only an installed official NetBird plugin and API surface confirmed compatible with its firmware.

#### Scenario: Required compatibility is absent
**ID:** `unsupported-router-is-not-mutated`
- **WHEN** the installed firmware, plugin, or required API fails read-only preflight
- **THEN** enrollment stops before mutating the router

### Requirement: NetBird peer settings are bounded
**ID:** `opnsense-netbird-peer-bounded`
North York OPNsense SHALL run its NetBird peer with NetBird-managed DNS and NetBird SSH capabilities disabled.

#### Scenario: Peer configuration is inspected
**ID:** `optional-peer-services-remain-disabled`
- **WHEN** the enrolled plugin settings are read
- **THEN** the peer is enabled without DNS takeover, interface assignment, firewall rules, or NetBird SSH capabilities

### Requirement: Enrollment does not activate routing
**ID:** `opnsense-enrollment-unrouted`
Enrolling North York OPNsense SHALL NOT assign it as a Network router or grant access to the North York LAN.

#### Scenario: Enrolled peer state is inspected
**ID:** `enrollment-keeps-routing-disabled`
- **WHEN** OPNsense is connected as a NetBird peer
- **THEN** the North York Network has no router assignment or effective routed-LAN policy
