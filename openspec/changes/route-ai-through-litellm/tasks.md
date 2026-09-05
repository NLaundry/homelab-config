## 1. Deliver scoped LiteLLM secrets

- [ ] 1.1 Render a LiteLLM-specific runtime file containing `OPENROUTER_API_KEY` and `LITELLM_MASTER_KEY` inside the existing volatile NASty secret directory.
- [ ] 1.2 Mount the service file read-only in `ai-gateway`, restrict service access, and fail startup on missing file, unsafe mode/ownership, writable mount, or unrelated credentials.

## 2. Configure native LiteLLM

- [ ] 2.1 Configure `services.litellm` on TCP 4000 with the runtime file, HTTP readiness, `Restart=on-failure`, no database, and environment references only.
- [ ] 2.2 Map `default` to `openrouter/z-ai/glm-5.3-flash`.
- [ ] 2.3 Modify the guest firewall contract and implementation to permit trusted-LAN TCP 4000 only.

## 3. Deliver deterministic and live evidence

- [ ] 3.1 Extend `tests/ai-gateway-vm.nix` with generated dummy-only LiteLLM/OpenRouter keys, rejection of production secret paths, a fake chat upstream, and assertions for read-only scope, readiness, auth denial without upstream traffic, default routing, response propagation, port policy, and restart recovery.
- [ ] 3.2 Implement root-level `tests/verify/ai-gateway-health.bats` as a default non-billable health check; add an `AI_GATEWAY_ADDRESS` Make variable exported as `HOMELAB_AI_GATEWAY_ADDRESS` to health and live-profile sources; add `curl` to the verify closure.
- [ ] 3.3 Implement `tests/verify/profiles/ai-gateway-live.bats` with a runtime key-file contract, strict timeout, bounded retries, one tiny-token chat request, response-schema checks, and redaction.
- [ ] 3.5 Execute the deterministic KVM and default verification sources; prove routine tests and deployment checks make no billable request.
- [ ] 3.6 Run `make check` for Nix evaluation and separately run strict OpenSpec validation for this change and its preceding AI stack members after sources exist. `make check` does not execute VM tests, OpenSpec, or shell tests.

## 4. Deploy and verify OpenRouter

- [ ] 4.1 Deploy LiteLLM, verify LAN health and unauthorized rejection, then explicitly run one real bounded `default` request and record sanitized evidence.
- [ ] 4.2 Verify rollback disables LiteLLM cleanly and document conditional rotation/revocation of the master and OpenRouter keys after exposure.
