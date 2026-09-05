---
id: service.openmemory
---

## Purpose

Trusted single-user clients share one authenticated memory service that preserves a stable user namespace across harnesses and exposes usable HTTP/MCP operations.

## ADDED Requirements

### Requirement: Clients can observe memory-service health
**ID:** `openmemory-health`
An authorized trusted-LAN client SHALL receive a successful health result from OpenMemory.

#### Scenario: Healthy memory service is probed
**ID:** `memory-health-probe-succeeds`
- **WHEN** an authorized LAN client probes OpenMemory after startup
- **THEN** the service reports healthy within the bounded timeout

### Requirement: Unauthorized memory requests are rejected
**ID:** `unauthenticated-memory-request-rejected`
OpenMemory SHALL reject a memory API or MCP request that lacks valid client authentication.

#### Scenario: Client omits the memory key
**ID:** `missing-memory-key-is-denied`
- **WHEN** a LAN client invokes a memory operation without a valid key
- **THEN** OpenMemory returns an authentication error without disclosing or changing memory state

### Requirement: Clients can store and retrieve memory
**ID:** `memory-store-retrieve`
An authorized client SHALL be able to store content and retrieve relevant content through OpenMemory's supported API or MCP operations.

#### Scenario: Client recalls stored context
**ID:** `stored-context-is-recalled`
- **WHEN** an authorized client stores content and submits a relevant query
- **THEN** OpenMemory returns the stored context in its retrieval result

### Requirement: Harnesses share one stable user namespace
**ID:** `stable-user-namespace`
OpenMemory SHALL associate durable memories supplied by authorized callers with the caller-provided stable opaque `user_id`.

#### Scenario: Two callers use the same user identity
**ID:** `cross-harness-recall-succeeds`
- **WHEN** a simulated `pi` caller stores memory and a simulated `claude-code` caller queries with the same stable `user_id`
- **THEN** the second caller can retrieve the first caller's memory

### Requirement: Client provenance remains distinguishable
**ID:** `client-provenance`
OpenMemory SHALL preserve caller-supplied provenance metadata separately from `user_id`.

#### Scenario: Memories arrive from different callers
**ID:** `provenance-does-not-split-user`
- **WHEN** simulated `pi` and `claude-code` callers store memories for the same stable user
- **THEN** their provenance remains distinguishable without creating separate user namespaces
