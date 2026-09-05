## Why

After model routing is stable, coding clients need one shared durable memory namespace. This final stack member adds Cavira OSS LongMemory independently so its runtime pin, embedding schema, state, authentication, and rollback can be accepted without changing the LiteLLM chat slice.

## What Changes

- Add `memory-embedding` mapped to `openrouter/openai/text-embedding-3-small` through LiteLLM.
- Package `https://github.com/CaviraOSS/LongMemory` from immutable source commit `80a807819c713a0d0cec041dda9e76df81d46983` in the Nix closure and run it as a native systemd service.
- Expose authenticated HTTP and Streamable HTTP MCP on TCP 7331; keep the dashboard disabled.
- Store SQLite data on a 32 GiB state volume and persist an embedding-schema fingerprint.
- Add `LONGMEMORY_API_KEY` to the encrypted AI secret document and render an OpenMemory-only file containing its API key plus the LiteLLM client credential, but not the OpenRouter key.
- Extend default deployed health and process-recovery behavior to OpenMemory.
- Add native-LiteLLM fake-upstream namespace, provenance, restart, egress, and schema-drift tests.

## Capabilities

### Configuration

- `configuration.secret-delivery`: apply read-only least-scoped delivery to OpenMemory (modified).
- `configuration.ai-gateway-microvm`: additionally admit TCP 7331 through the guest firewall (modified).
- `configuration.litellm`: add the selected memory embedding alias (modified).
- `configuration.openmemory`: pinned source-built runtime, listener, authentication, SQLite layout, LiteLLM dependency, and 1536-dimensional schema (new).

### Lifecycle

- `lifecycle.ai-gateway`: extend process recovery and deployed activation-health behavior to OpenMemory (modified).
- `lifecycle.openmemory`: dependency ordering, state survival, and embedding-schema migration guard (new).

### Service

- `service.ai-gateway`: add authenticated embedding routing (modified).
- `service.openmemory`: authenticated HTTP/MCP health, store/retrieve, shared stable user namespace, and provenance (new).

## Verification intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| `gateway-secret-delivery`, `gateway-secret-scope` | test | `tests/openmemory-vm.nix` | OpenMemory receives one read-only file containing only its API key and LiteLLM client credential. |
| `gateway-firewall` | test | `tests/ai-gateway-vm.nix` | The composed guest admits only TCP 4000 and 7331. |
| `openrouter-memory-embedding`, `authenticated-embedding-routing` | test | `tests/openmemory-vm.nix` | Native LiteLLM routes authenticated embeddings to a fake OpenRouter-compatible upstream without undeclared egress. |
| `failed-service-restart` | test | `tests/openmemory-vm.nix` | An injected LongMemory process failure recovers within the restart window. |
| `activation-health` | test | `tests/verify/ai-gateway-health.bats` | Default deployment verification fails when enabled LongMemory is unhealthy. |
| `openmemory-runtime`, `openmemory-listener`, `openmemory-authentication`, `openmemory-state-layout`, `openmemory-litellm-dependency`, `openmemory-litellm-authentication`, `openmemory-embedding-dimensions` | test | `tests/openmemory-vm.nix` | The pinned native service runs with authenticated protocols, SQLite state, and the selected gateway-backed embedding schema. |
| `openmemory-start-order`, `memory-survives-service-restart`, `memory-survives-guest-restart`, `embedding-schema-change-control` | test | `tests/openmemory-vm.nix` | Dependencies gate startup, state survives restarts, and schema drift fails closed pending migration. |
| `openmemory-health`, `unauthenticated-memory-request-rejected`, `memory-store-retrieve`, `stable-user-namespace`, `client-provenance` | test | `tests/openmemory-vm.nix` | Authorized clients share one namespace with provenance while unauthorized operations are denied. |

## Impact

- Adds a fixed-output LongMemory package and native systemd service inside `ai-gateway`; no container runtime is introduced.
- Adds port 7331, a 32 GiB state volume, and OpenMemory-specific SOPS rendering.
- Adds the LiteLLM embedding route, OpenMemory KVM test, and deployed health coverage.
- Does not add Open WebUI, local inference, GPU passthrough, TLS, internal DNS, or multi-user authorization.
