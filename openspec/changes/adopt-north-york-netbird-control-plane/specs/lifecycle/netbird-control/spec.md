---
id: lifecycle.netbird-control
---

## Purpose

NetBird adoption and recovery preserve live service while bringing remote objects and protected state under repository control.

## ADDED Requirements

### Requirement: NetBird adoption preserves service
**ID:** `netbird-adoption-preserves-service`
Adopting an existing NetBird object SHALL preserve its remote identity and SHALL not activate routing or change an unrelated site.

#### Scenario: Existing North York Network is adopted
**ID:** `north-york-import-is-nondisruptive`
- **WHEN** the existing North York Network is imported and the baseline is applied
- **THEN** its identity is retained without replacement, routing activation, or change to unmanaged objects

### Requirement: NetBird state is recoverable
**ID:** `netbird-state-recoverable`
An operator SHALL be able to restore the encrypted NetBird state from an independently backed-up snapshot without introducing a remote change.

#### Scenario: Primary state is unavailable
**ID:** `encrypted-state-is-restored`
- **WHEN** the primary local state is unavailable
- **THEN** an operator restores a protected snapshot into an isolated state path and obtains an equivalent read-only refresh result
