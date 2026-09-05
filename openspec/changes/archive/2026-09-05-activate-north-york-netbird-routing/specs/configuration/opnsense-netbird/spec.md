---
id: configuration.opnsense-netbird
---

## ADDED Requirements

### Requirement: OPNsense supports approved NetBird forwarding
**ID:** `opnsense-netbird-forwarding`
North York OPNsense SHALL forward approved NetBird traffic using the official plugin's built-in firewall integration, with LAN access and server-route acceptance enabled and NetBird DNS and SSH disabled.

#### Scenario: Routing settings are inspected
**ID:** `plugin-routing-is-bounded`
- **WHEN** the activated plugin settings are read
- **THEN** approved North York forwarding is enabled without DNS takeover, NetBird SSH, or client-route acceptance
- **AND** this change adds no manual interface assignment or persistent firewall rule

## MODIFIED Requirements

### Requirement: Enrollment does not activate routing
**ID:** `opnsense-enrollment-unrouted`
Enrollment alone SHALL NOT activate North York LAN access; routing SHALL require a separate explicitly approved activation.

#### Scenario: Enrolled peer state is inspected
**ID:** `enrollment-keeps-routing-disabled`
- **WHEN** OPNsense is connected as a NetBird peer before an approved routing activation
- **THEN** the North York Network has no router assignment or effective routed-LAN policy
