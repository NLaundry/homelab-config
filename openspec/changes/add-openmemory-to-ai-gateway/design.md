## Context

This final stack member assumes authenticated LiteLLM chat routing is deployed. Cavira OSS renamed the project and changed its runtime contract over time, and its published GHCR package is not anonymously retrievable. This change therefore selects the current LongMemory source contract at immutable commit `80a807819c713a0d0cec041dda9e76df81d46983`: Node 20+, TCP 7331, `/health`, Streamable HTTP MCP, SQLite, `LONGMEMORY_*` configuration, and an OpenAI-compatible embedding client.

## Goals / Non-Goals

**Goals:**

- Add authenticated HTTP and Streamable HTTP MCP memory operations.
- Give harnesses one stable shared user namespace with separate provenance.
- Route embeddings through native LiteLLM while keeping the OpenRouter key only in LiteLLM.
- Persist SQLite state and embedding schema across restarts.
- Fail closed on embedding-schema drift.

**Non-Goals:**

- Dashboard, container runtime, Open WebUI, local inference, GPU passthrough, public ingress, TLS, internal DNS, or multi-user authorization.

## Decisions

- Fetch `https://github.com/CaviraOSS/LongMemory` from commit `80a807819c713a0d0cec041dda9e76df81d46983` with fixed Nix source/dependency hashes, package it in the flake closure, and run `node dist/server/index.js` as a hardened native systemd service.
- Configure `LONGMEMORY_HOST=0.0.0.0`, `LONGMEMORY_PORT=7331`, `LONGMEMORY_DB_PATH=/var/lib/openmemory/longmemory.db`, `LONGMEMORY_MCP_HTTP=true`, and disable the dashboard.
- Configure `LONGMEMORY_EMBEDDING_PROVIDER=openai`, `LONGMEMORY_EMBEDDING_TIER=deep`, `LONGMEMORY_EMBEDDING_DIMENSION=1536`, `LONGMEMORY_OPENAI_BASE_URL=http://127.0.0.1:4000/v1`, and `LONGMEMORY_OPENAI_EMBEDDING_MODEL=memory-embedding`.
- Add `memory-embedding` -> `openrouter/openai/text-embedding-3-small` and use 1536 dimensions.
- Add `LONGMEMORY_API_KEY` to the encrypted AI secret document. Render an OpenMemory-only read-only file with `LONGMEMORY_API_KEY` and `OPENAI_API_KEY` derived from `LITELLM_MASTER_KEY`; never include `OPENROUTER_API_KEY`.
- Store SQLite state on a 32 GiB volume mounted at `/var/lib/openmemory` and keep the guest root disposable.
- Persist a fingerprint of embedding alias, upstream model, and dimensions beneath `/var/lib/openmemory`; block startup/writes on drift until an explicit rebuild or migration marker is selected.
- Prove the caller-supplied identity contract with simulated `pi` and `claude-code` callers that share one generated opaque `user_id` while supplying distinct provenance metadata; real client adapter configuration remains out of scope.
- Extend the default deployed health source and generic process-recovery contract to enabled LongMemory.

## Verification design

### `tests/openmemory-vm.nix`

- Expose a native forced-KVM private NixOS test through the flake with repository-required isolation declarations.
- Build the pinned Nix package, run native LiteLLM, use generated dummy-only memory/LiteLLM keys, fake only the OpenRouter-compatible upstream, attach a disposable persistent volume, and install an outbound egress trap.
- Assert the exact runtime pin, read-only key allowlist, health, auth denial, HTTP/MCP store/retrieve, stable cross-harness namespace, provenance, embedding alias/routing, port policy, dependency order, schema fingerprint/drift rejection, automatic process recovery, and service/guest restart survival.
- Reject production secret paths and unexpected network destinations.
- Fail on protocol, egress, state, auth, schema, recovery, or timeout failure.

### `tests/verify/ai-gateway-health.bats`

- Extend the existing non-billable deployment check to probe enabled LongMemory readiness on port 7331.
- Fail with the guest service name when LongMemory remains unhealthy.
- Never invoke chat, embeddings, or memory mutation endpoints.

## Risks / Trade-offs

- **[Upstream contract drifts]** -> Pin the exact commit and fixed-output hashes; upgrades require a separate reviewed change.
- **[Source package is harder than an OCI pull]** -> Keep all build inputs in the Nix closure and test the resulting service contract directly.
- **[Embedding change corrupts retrieval]** -> Pin model and 1536 dimensions and require explicit migration/rebuild.
- **[State is lost]** -> Keep SQLite on the explicit volume and test service and guest restarts.
- **[One guest is one failure domain]** -> Keep separate units, secrets, state ownership, and acceptance checks.

## Migration Plan

1. Package and acceptance-test the selected LongMemory commit.
2. Add the embedding alias and private VM test before production state.
3. Add the encrypted API key, service-specific rendered file, and state volume.
4. Deploy, run add/search, restart service/guest, and confirm retrieval.
5. Rollback stops LongMemory while retaining the volume; destructive state/schema changes require a separate migration artifact.
