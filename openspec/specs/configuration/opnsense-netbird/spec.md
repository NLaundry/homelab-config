---
id: configuration.opnsense-netbird
---

## Purpose

OPNsense realizes a bounded NetBird peer through the supported official plugin without enabling routed LAN access.

## Requirements

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
Enrollment alone SHALL NOT activate North York LAN access; routing SHALL require a separate explicitly approved activation.

#### Scenario: Enrolled peer state is inspected
**ID:** `enrollment-keeps-routing-disabled`
- **WHEN** OPNsense is connected as a NetBird peer before an approved routing activation
- **THEN** the North York Network has no router assignment or effective routed-LAN policy

### Requirement: OPNsense supports approved NetBird forwarding
**ID:** `opnsense-netbird-forwarding`
North York OPNsense SHALL forward approved NetBird traffic using the official plugin's built-in firewall integration, with LAN access and server-route acceptance enabled and NetBird DNS and SSH disabled.

#### Scenario: Routing settings are inspected
**ID:** `plugin-routing-is-bounded`
- **WHEN** the activated plugin settings are read
- **THEN** approved North York forwarding is enabled without DNS takeover, NetBird SSH, or client-route acceptance
- **AND** this change adds no manual interface assignment or persistent firewall rule
