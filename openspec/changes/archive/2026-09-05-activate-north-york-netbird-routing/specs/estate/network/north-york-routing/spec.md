---
id: estate.network.north-york-routing
---

## Purpose

The Estate identifies the node and failure boundary that connect the NetBird overlay to North York clientless resources.

## ADDED Requirements

### Requirement: OPNsense owns the North York overlay route
**ID:** `north-york-opnsense-routes-overlay`
The North York OPNsense host SHALL be the routing boundary between the NetBird overlay and North York LAN resources.

#### Scenario: Overlay route placement is inspected
**ID:** `route-terminates-on-north-york-router`
- **WHEN** the managed Estate and network control state are inspected
- **THEN** the North York overlay route terminates on the North York OPNsense host rather than a dedicated routing workload

### Requirement: North York routing has one failure boundary
**ID:** `north-york-routing-failure-boundary`
Remote overlay access to clientless North York LAN resources SHALL depend on the North York OPNsense routing peer while local LAN operation remains independent of that route.

#### Scenario: Routing peer is unavailable
**ID:** `local-lan-outlives-overlay-route`
- **WHEN** the North York NetBird routing peer is unavailable
- **THEN** remote routed access is unavailable without implying failure of local North York LAN communication
