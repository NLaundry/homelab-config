---
id: configuration.litellm
---

## Purpose

The AI gateway realizes model routing through the native flake-pinned LiteLLM service with explicit authentication, listener, and provider mapping.

## ADDED Requirements

### Requirement: LiteLLM uses the native NixOS service
**ID:** `native-litellm-service`
The `ai-gateway` configuration SHALL run the flake-pinned nixpkgs LiteLLM package through `services.litellm` rather than an OCI runtime.

#### Scenario: LiteLLM realization is evaluated
**ID:** `native-service-is-selected`
- **WHEN** the guest configuration is evaluated
- **THEN** the LiteLLM executable and unit resolve from the locked Nix package set

### Requirement: LiteLLM uses the selected listener
**ID:** `litellm-listener`
LiteLLM SHALL listen on guest TCP port 4000 for trusted-LAN clients.

#### Scenario: Guest listener is inspected
**ID:** `listener-uses-port-4000`
- **WHEN** LiteLLM reaches readiness
- **THEN** its API accepts connections on port 4000 and no alternate public port

### Requirement: LiteLLM credentials come from runtime state
**ID:** `litellm-authentication`
LiteLLM SHALL load `LITELLM_MASTER_KEY` and `OPENROUTER_API_KEY` from its service-specific runtime environment file.

#### Scenario: Generated LiteLLM configuration is inspected
**ID:** `credentials-are-environment-references`
- **WHEN** generated service settings are evaluated
- **THEN** they reference environment variables without containing credential values

### Requirement: The default chat alias uses GLM 5.3 Flash
**ID:** `openrouter-default-model`
LiteLLM SHALL map the `default` model alias to `openrouter/z-ai/glm-5.3-flash`.

#### Scenario: Default model is requested
**ID:** `default-alias-selects-glm`
- **WHEN** a client submits a completion for `default`
- **THEN** LiteLLM selects the configured GLM 5.3 Flash OpenRouter route

### Requirement: Initial LiteLLM operation is stateless
**ID:** `litellm-stateless-mode`
LiteLLM SHALL operate without a database until persistent gateway features are proposed separately.

#### Scenario: LiteLLM configuration is evaluated
**ID:** `database-is-not-required`
- **WHEN** the initial gateway closure and service dependencies are evaluated
- **THEN** no database service or connection is required for LiteLLM readiness
