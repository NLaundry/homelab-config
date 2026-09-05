---
id: lifecycle.netbird-control
---

## Purpose

NetBird adoption preserves live object identity while bringing the selected North York baseline under repository control.

## ADDED Requirements

### Requirement: NetBird adoption preserves service
**ID:** `netbird-adoption-preserves-service`
Adopting an existing NetBird object SHALL preserve its remote identity and SHALL not activate routing or change an unrelated account object.

#### Scenario: Existing North York objects are adopted
**ID:** `north-york-import-is-nondisruptive`
- **WHEN** the existing North York Network or LAN resource is imported and the baseline is applied
- **THEN** its identity is retained without replacement, routing activation, or change to unmanaged objects
