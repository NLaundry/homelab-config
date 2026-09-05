## 1. Package the selected LongMemory runtime

- [ ] 1.1 Package `https://github.com/CaviraOSS/LongMemory` from commit `80a807819c713a0d0cec041dda9e76df81d46983` with fixed Nix source and pnpm dependency hashes; expose the server entry point from the flake closure.
- [ ] 1.2 Acceptance-test the selected contract: Node 20+, port 7331, `/health`, Streamable HTTP MCP, `LONGMEMORY_API_KEY`, SQLite path, custom OpenAI-compatible base URL, `OPENAI_API_KEY`, model alias, and explicit dimensions.
- [ ] 1.3 Confirm 1536 dimensions for `openai/text-embedding-3-small` and record the immutable source revision and hashes in the implementation evidence.

## 2. Extend the gateway for memory

- [ ] 2.1 Add `memory-embedding` mapped to `openrouter/openai/text-embedding-3-small` through native LiteLLM and assert the alias in `tests/openmemory-vm.nix`.
- [ ] 2.2 Modify the guest firewall and `tests/ai-gateway-vm.nix` expectations to permit only TCP 4000 and 7331.
- [ ] 2.3 Add `LONGMEMORY_API_KEY` to the encrypted AI secret document using the existing recipients; preserve `OPENROUTER_API_KEY` and `LITELLM_MASTER_KEY`.
- [ ] 2.4 Add the hardened native LongMemory systemd service with the selected `LONGMEMORY_*` variables, local LiteLLM base URL, `memory-embedding`, 1536 dimensions, restart policy, and disabled dashboard.
- [ ] 2.5 Add a 32 GiB state volume mounted at `/var/lib/openmemory`; set the SQLite path beneath it while keeping the guest root disposable.
- [ ] 2.6 Render an OpenMemory-only read-only runtime file containing `LONGMEMORY_API_KEY` and `OPENAI_API_KEY` derived from `LITELLM_MASTER_KEY`; reject `OPENROUTER_API_KEY` and every unrelated key.
- [ ] 2.7 Define acceptance fixtures for simulated `pi` and `claude-code` callers that send the same generated opaque `user_id` with distinct caller-provenance metadata; deploying real client adapters remains out of scope.
- [ ] 2.8 Persist a fingerprint of embedding alias, upstream model, and dimensions beneath `/var/lib/openmemory` and block startup/writes on drift until an explicit rebuild or migration marker is selected.
- [ ] 2.9 Extend `tests/verify/ai-gateway-health.bats` so default deployment verification fails when enabled LongMemory is unhealthy, without calling chat, embeddings, or memory mutation endpoints.

## 3. Deliver OpenMemory evidence

- [ ] 3.1 Implement and register `tests/openmemory-vm.nix` with exact repository isolation declarations, the pinned Nix package, generated dummy-only memory/LiteLLM keys, production-secret-path rejection, native LiteLLM, a fake OpenRouter-compatible upstream, a disposable persistent volume, and an egress trap.
- [ ] 3.2 Assert the read-only OpenMemory key allowlist; runtime pin; health; dashboard endpoint rejection; evaluated 32 GiB volume and live SQLite path beneath `/var/lib/openmemory`; HTTP/MCP store/retrieve; denied reads expose no stored content; denied writes leave state unchanged; authenticated embedding routing; shared namespace; provenance; dependency ordering; schema fingerprint persistence across guest restart and drift rejection; port/egress policy; injected LongMemory process failure and bounded automatic recovery; and service/guest restart survival.
- [ ] 3.3 Confirm bindings `openmemory-secret-mount`, `ai-gateway-vm-configuration`, `openmemory-embedding-configuration`, `openmemory-embedding-route`, `openmemory-service-recovery`, `deployed-ai-health`, `openmemory-guest-configuration`, `openmemory-transitions`, and `openmemory-protocols`.
- [ ] 3.4 Execute the updated gateway VM, OpenMemory VM, and default deployed health source through the registered harnesses; record the immutable revision and evidence boundary.
- [ ] 3.5 Add direct requirement observations for automated bindings, run enforcement-quality with this change's projected spec root, and validate the complete stack strictly after sources exist.

## 4. Deploy and verify memory

- [ ] 4.1 Deploy LongMemory and run an authenticated LAN add/search check without recording keys or memory content.
- [ ] 4.2 Inject one process failure, then restart the service and guest and confirm automatic recovery, retrieval, and the recorded embedding schema survive.
- [ ] 4.3 Verify rollback stops LongMemory while retaining the state volume; reject destructive state/schema changes without a separate migration artifact.
