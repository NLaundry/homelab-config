## Context

This stack member assumes the previous prefixes provide host-side SOPS decryption and a reachable, default-deny `ai-gateway` guest. LiteLLM 1.86.0 and `services.litellm` are available in the pinned nixpkgs. The guest needs remote provider egress, but routine tests must remain private and non-billable.

## Goals / Non-Goals

**Goals:**

- Deliver least-scoped runtime secrets to LiteLLM.
- Provide authenticated OpenAI-compatible chat routing on port 4000.
- Route `default` to OpenRouter GLM 5.3 Flash.
- Prove deterministic routing plus one explicit real request.

**Non-Goals:**

- Embeddings, OpenMemory, databases, virtual keys, budgets, UI, TLS, or automatic billable checks.

## Decisions

- Render a LiteLLM-specific read-only environment file containing `OPENROUTER_API_KEY` and `LITELLM_MASTER_KEY`; do not expose the complete host secret tree.
- Use native `services.litellm`, direct systemd supervision, `Restart=on-failure`, HTTP readiness, and no database.
- Listen on TCP 4000 and change the guest firewall from default-deny to permit only 4000 from the trusted LAN.
- Map `default` to `openrouter/z-ai/glm-5.3-flash`.
- Test with generated dummy keys and a fake OpenRouter-compatible upstream inside the private VM topology.
- Keep a non-billable root-level health check in default deployment verification; keep the real tiny-token chat request in an explicit profile.

## Verification design

### `tests/ai-gateway-vm.nix`

- Extend the existing native NixOS KVM test with generated dummy-only keys and a fake chat upstream.
- Assert read-only scoped delivery, readiness, auth rejection without upstream traffic, successful `default` routing, response propagation, port 4000 policy, and restart recovery.
- Reject production secret paths and physical-LAN routes.
- Fail on assertion or timeout.

### `tests/verify/ai-gateway-health.bats`

- Probe enabled guest health from a LAN client without making a provider request.
- Include it in the default packaged verification app without a source-count or registry test.
- Fail deployment verification on unreachable or unhealthy enabled services.

### `tests/verify/profiles/ai-gateway-live.bats`

- Accept the LiteLLM key through a runtime key-file contract.
- Make one tiny-token request with strict timeout and bounded retries.
- Validate response shape, not generated prose; redact headers, keys, and content.
- Remain excluded from routine tests and default deployment checks.

## Risks / Trade-offs

- **[Provider request costs money]** -> Make exactly one explicit bounded request and record that it does not prove uptime, quality, cost stability, or load.
- **[Guest can alter host secret]** -> Use service-specific read-only mounts and fail on mode/ownership mismatch.
- **[No TLS]** -> Restrict to the trusted LAN and require the master key; defer TLS until internal DNS exists.

## Migration Plan

1. Add guest secret delivery and prove dummy-only tests.
2. Enable LiteLLM and port 4000 in the private VM test.
3. Add default non-billable health verification and explicit live profile.
4. Deploy, verify health/auth, then run one real `default` request.
5. Rollback disables LiteLLM; rotate/revoke keys if exposure occurred.
