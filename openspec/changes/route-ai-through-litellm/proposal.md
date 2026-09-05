## Why

With the guest reachable, the homelab needs one authenticated model gateway that keeps the upstream credential out of clients. This third stack member adds LiteLLM and proves one bounded OpenRouter route without adding memory or database features.

## What Changes

- Deliver service-specific read-only runtime secret files from NASty into `ai-gateway`.
- Run native nixpkgs `services.litellm` on TCP 4000 with master-key authentication and no database.
- Map `default` to `openrouter/z-ai/glm-5.3-flash`.
- Open only TCP 4000 through the guest firewall.
- Add deterministic fake-upstream tests, non-billable default health verification, and one opt-in real OpenRouter request.

## Capabilities

### Configuration

- `configuration.secret-delivery`: add least-scoped read-only guest service files (modified).
- `configuration.ai-gateway-microvm`: admit the LiteLLM listener through the guest firewall (modified).
- `configuration.litellm`: native service, listener, credentials, default route, and stateless mode (new).

### Lifecycle

- `lifecycle.ai-gateway`: add failed-service restart and deployed activation-health behavior (modified).

### Service

- `service.ai-gateway`: authenticated health and OpenAI-compatible chat routing with unauthorized rejection (new).

## Verification intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| `gateway-secret-delivery`, `gateway-secret-scope` | test | `tests/ai-gateway-vm.nix` | LiteLLM receives its read-only service file without unrelated credentials. |
| `gateway-firewall` | test | `tests/ai-gateway-vm.nix` | TCP 4000 is reachable in the private topology while undeclared ports remain blocked. |
| `native-litellm-service`, `litellm-listener`, `litellm-authentication`, `openrouter-default-model`, `litellm-stateless-mode` | test | `tests/ai-gateway-vm.nix` | Native LiteLLM becomes ready and routes authenticated chat through a fake compatible upstream. |
| `failed-service-restart` | test | `tests/ai-gateway-vm.nix` | An injected LiteLLM process failure recovers within the restart window. |
| `activation-health` | test | `tests/verify/ai-gateway-health.bats` | Default deployment verification fails when an enabled guest service is unhealthy. |
| `gateway-health`, `unauthenticated-request-rejected`, `authenticated-model-routing` | test | `tests/ai-gateway-vm.nix` | Health and authenticated chat succeed while missing auth is denied without upstream traffic. |
| `real-openrouter-routing` | test | `tests/verify/profiles/ai-gateway-live.bats` | One explicit tiny-token LAN request returns a valid real OpenRouter response without leaking credentials or prose. |

## Impact

- Adds native LiteLLM configuration and port 4000 to the guest.
- Adds runtime secret sharing for `OPENROUTER_API_KEY` and `LITELLM_MASTER_KEY`.
- Adds private VM routing tests and default/opt-in verification sources.
- Adds `curl` and required secret tooling to the verify closure.
- Does not add embeddings, OpenMemory, PostgreSQL, Qdrant, virtual keys, or a dashboard.
