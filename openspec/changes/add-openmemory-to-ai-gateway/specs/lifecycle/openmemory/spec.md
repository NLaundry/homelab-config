---
id: lifecycle.openmemory
---

## Purpose

OpenMemory starts only when its dependencies are ready, retains stored memory through ordinary restarts, and fails closed on embedding-schema drift.

## ADDED Requirements

### Requirement: OpenMemory starts after its dependencies
**ID:** `openmemory-start-order`
The AI guest SHALL start OpenMemory only after its state volume is mounted and its local embedding gateway is ready.

#### Scenario: AI guest boots
**ID:** `memory-waits-for-volume-and-gateway`
- **WHEN** the guest starts with OpenMemory enabled
- **THEN** OpenMemory does not accept traffic before both declared dependencies are ready

### Requirement: Memory survives service restart
**ID:** `memory-survives-service-restart`
A stored memory SHALL remain retrievable after the OpenMemory service is restarted.

#### Scenario: OpenMemory process restarts
**ID:** `stored-memory-survives-process-restart`
- **WHEN** a memory is stored and the OpenMemory service restarts
- **THEN** the same memory remains retrievable under its original user namespace

### Requirement: Memory survives guest restart
**ID:** `memory-survives-guest-restart`
A stored memory SHALL remain retrievable after the `ai-gateway` guest is restarted.

#### Scenario: AI guest reboots
**ID:** `stored-memory-survives-guest-reboot`
- **WHEN** a memory is stored and the guest completes a reboot
- **THEN** the same memory remains retrievable from the mounted state volume

### Requirement: Embedding schema changes require migration
**ID:** `embedding-schema-change-control`
OpenMemory SHALL persist a fingerprint of its embedding alias, upstream model, and dimensions beneath `/var/lib/openmemory` and reject a change until an explicit memory rebuild or migration is selected.

#### Scenario: Embedding fingerprint survives guest restart
**ID:** `embedding-fingerprint-survives-guest-reboot`
- **WHEN** the configured embedding schema is recorded and the guest completes a reboot
- **THEN** the same fingerprint remains available from the mounted state volume

#### Scenario: Configured embedding schema drifts
**ID:** `embedding-drift-fails-closed`
- **WHEN** stored memory exists and the configured embedding schema differs from the recorded schema
- **THEN** OpenMemory does not accept new writes until the operator selects a rebuild or migration
