---
id: configuration.openmemory
---

## Purpose

The AI guest realizes Cavira OSS LongMemory as a source-pinned, authenticated, SQLite-backed native service that obtains embeddings through the local model gateway.

## ADDED Requirements

### Requirement: OpenMemory uses an immutable runtime artifact
**ID:** `openmemory-runtime`
The `ai-gateway` configuration SHALL package `https://github.com/CaviraOSS/LongMemory` from commit `80a807819c713a0d0cec041dda9e76df81d46983` with fixed Nix source and dependency hashes.

#### Scenario: OpenMemory runtime is evaluated
**ID:** `source-revision-is-fixed`
- **WHEN** the guest package configuration is evaluated
- **THEN** the source revision is exact and all fetched source and dependency inputs are content-addressed

### Requirement: OpenMemory uses the selected listener
**ID:** `openmemory-listener`
OpenMemory SHALL expose its authenticated HTTP and Streamable HTTP MCP service on guest TCP port 7331.

#### Scenario: OpenMemory listener is inspected
**ID:** `memory-api-uses-port-7331`
- **WHEN** OpenMemory reaches readiness
- **THEN** its API and MCP endpoint are available on port 7331 while its dashboard remains disabled

### Requirement: OpenMemory authentication comes from runtime state
**ID:** `openmemory-authentication`
OpenMemory SHALL load `LONGMEMORY_API_KEY` from its service-specific runtime environment file.

#### Scenario: OpenMemory unit is evaluated
**ID:** `memory-key-is-runtime-only`
- **WHEN** generated package and unit settings are inspected
- **THEN** they reference the runtime key without containing its value

### Requirement: OpenMemory stores data on the selected state volume
**ID:** `openmemory-state-layout`
OpenMemory SHALL store its SQLite database beneath `/var/lib/openmemory` on a 32 GiB guest volume.

#### Scenario: OpenMemory writes durable state
**ID:** `sqlite-path-uses-state-volume`
- **WHEN** OpenMemory creates or updates its SQLite database
- **THEN** the files resolve to the explicit state volume rather than the disposable guest root

### Requirement: OpenMemory obtains embeddings through LiteLLM
**ID:** `openmemory-litellm-dependency`
OpenMemory SHALL use `http://127.0.0.1:4000/v1` and the `memory-embedding` alias for embeddings.

#### Scenario: OpenMemory ingests content
**ID:** `embedding-request-uses-gateway`
- **WHEN** OpenMemory creates an embedding during ingestion
- **THEN** the request is sent to the guest-local gateway alias rather than directly to an upstream provider

### Requirement: OpenMemory authenticates to LiteLLM with the selected gateway key
**ID:** `openmemory-litellm-authentication`
OpenMemory SHALL load the gateway master credential as `OPENAI_API_KEY` from its service-specific runtime file.

#### Scenario: OpenMemory embedding client is evaluated
**ID:** `embedding-client-key-is-runtime-only`
- **WHEN** generated package and unit settings are inspected
- **THEN** they reference the runtime gateway key without containing its value

### Requirement: OpenMemory uses the selected embedding dimensions
**ID:** `openmemory-embedding-dimensions`
OpenMemory SHALL configure and record 1536 dimensions for the `memory-embedding` schema.

#### Scenario: OpenMemory initializes its memory store
**ID:** `embedding-dimensions-are-recorded`
- **WHEN** the memory store is initialized
- **THEN** its recorded embedding schema declares 1536 dimensions
