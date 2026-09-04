# LocalLLM with shared memory

Explore a self-hosted AI platform that gives coding harnesses and a web UI a common long-term memory service while centralizing model routing.

## Provisional architecture

Run one NixOS MicroVM on NASty with its own stable LAN IP. The VM is the isolation, network-identity, deployment, and lifecycle boundary for the full AI stack. Run each application as a pinned OCI container inside the guest, managed declaratively through NixOS and systemd/Podman Quadlet rather than placing each application in a separate MicroVM.

```text
LAN clients
  ├─ Open WebUI ───────────────┐
  ├─ coding harnesses ─────────┼─ LiteLLM ─ model providers
  └─ OpenMemory MCP/API ───────┘
             │
             ├─ SQLite metadata
             └─ Qdrant vectors

PostgreSQL
  ├─ LiteLLM database and role
  └─ Open WebUI database and role
```

OpenMemory is the canonical cross-harness memory authority. Open WebUI is the human chat surface. LiteLLM is the model gateway and the only service that holds upstream provider credentials. OpenMemory and Open WebUI each receive restricted LiteLLM virtual keys.

Local model inference is not yet decided. LiteLLM must support remote providers initially and leave room to add local inference later.

## Network shape

Give the MicroVM one address distinct from the NAS. Until internal DNS exists, clients can use that address with separate ports, or temporary `/etc/hosts` entries for the future service names. PostgreSQL and Qdrant stay guest-internal. Open WebUI, LiteLLM, and OpenMemory expose only their required LAN interfaces.

Prefer a bridged TAP interface so the NAS, LAN clients, and future monitoring can communicate normally with the guest. This requires a deliberate migration from the NAS's current interactive NetworkManager configuration to a declared bridge or an equivalent safe realization.

## Memory identity

Use one stable, opaque `user_id` for a person across every harness. Use the OpenMemory client/application name to preserve source provenance, for example `pi`, `claude-code`, or `open-webui`. Do not encode the harness into `user_id`, because that would create separate memory silos.

OpenMemory's caller-supplied `user_id` provides logical namespace isolation, not proven authentication. This is acceptable for an initially trusted single-user LAN deployment. Before adding users, an authenticated boundary must derive `user_id` from an immutable Kanidm OIDC subject so callers cannot claim another person's namespace. Separate per-user instances remain a fallback.

Open WebUI's internal memory should not silently become a second memory authority. Its OpenMemory integration must be verified against the pinned MCP transports: current Open WebUI uses Streamable HTTP MCP while documented OpenMemory examples use older SSE endpoints. An adapter may be required. Multi-user WebUI integration must preserve the authenticated user's identity.

## Persistence

Keep the MicroVM root disposable or read-only and place durable data on an explicit state volume. State includes PostgreSQL, OpenMemory SQLite, Qdrant, Open WebUI state/uploads, and stable encryption keys such as `LITELLM_SALT_KEY` and `WEBUI_SECRET_KEY`.

Use PostgreSQL from the start for LiteLLM's persistent gateway features and for Open WebUI, with separate databases and roles. Keep OpenMemory on its officially documented SQLite plus Qdrant topology unless upstream support and migration behavior justify a change.

Backups must be application-aware or taken during a bounded writer shutdown. Upgrade rollback must account for database migrations: snapshot state, update pinned images, run migrations, probe the real APIs, and restore both old images and state on incompatible failure.

## Repository fit

The repository currently has no production MicroVM, OCI, secret-management, ingress, application backup, or guest-network platform. This idea therefore establishes a platform boundary rather than reusing one. Existing design notes prefer OCI for image-first applications; the MicroVM is justified here by the distinct LAN identity, stronger kernel boundary, and independent lifecycle for the complete AI stack.

A future proposal will likely touch:

- Service: reachable model routing and cross-harness memory outcomes.
- Estate: MicroVM placement, dependencies, state ownership, trust boundary, and failure domain.
- Configuration: selected products, versions, guest address, listeners, mounts, secrets, and firewall.
- Lifecycle: boot ordering, upgrades, rollback, backup, restore, and recovery drills.
- Governance only if the change introduces a reusable repository-wide MicroVM/OCI convention.

Current Specbase coverage has no hanging claims, stale bindings, or orphaned enforcement. Existing NAS lifecycle evidence is partly manual/degraded; a proposal should explicitly reuse, strengthen, or defer that host-storage evidence.

## Open questions

- Guest LAN address and bridge migration plan.
- Initial TLS approach before DNS exists.
- Whether local model inference or GPU passthrough is in the first scope.
- Exact pinned releases and OCI image digests.
- OpenMemory/Open WebUI MCP transport compatibility.
- Authenticated `OIDC sub -> user_id` bridge design for future users.
- Secret delivery and encrypted state location.
- Resource sizing, observability, backup destination, and restore objectives.

## Research references

- OpenMemory application: https://github.com/mem0ai/mem0/tree/main/openmemory
- OpenMemory Compose: https://github.com/mem0ai/mem0/blob/main/openmemory/docker-compose.yml
- Mem0 LiteLLM provider: https://docs.mem0.ai/components/llms/models/litellm
- LiteLLM deployment: https://docs.litellm.ai/docs/proxy/deploy
- LiteLLM Open WebUI integration: https://docs.litellm.ai/docs/tutorials/openweb_ui
- Open WebUI quick start: https://docs.openwebui.com/getting-started/quick-start/
- Open WebUI environment configuration: https://docs.openwebui.com/reference/env-configuration
- MicroVM.nix: https://microvm-nix.github.io/microvm.nix/
- NixOS declarative containers: https://nixos.org/manual/nixos/stable/#sec-declarative-containers
