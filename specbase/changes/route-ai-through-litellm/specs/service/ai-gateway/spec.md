---
id: service.ai-gateway
---

## Purpose

Trusted-LAN clients receive a healthy, authenticated OpenAI-compatible gateway for chat requests while unauthorized use is rejected.

## ADDED Requirements

### Requirement: Clients can observe gateway health
**ID:** `gateway-health`
An authorized trusted-LAN client SHALL receive a successful LiteLLM liveness and readiness result from the AI gateway.

#### Scenario: Healthy gateway is probed
**ID:** `health-probe-succeeds`
- **WHEN** an authorized LAN client calls the gateway health endpoints after startup
- **THEN** the gateway reports live and ready within the bounded timeout

### Requirement: Unauthorized model requests are rejected
**ID:** `unauthenticated-request-rejected`
The AI gateway SHALL reject a chat request that lacks valid client authentication.

#### Scenario: Client omits its gateway key
**ID:** `missing-key-is-denied`
- **WHEN** a LAN client submits an OpenAI-compatible chat request without a valid key
- **THEN** the gateway returns an authentication error without contacting the upstream provider

### Requirement: Authorized chat requests use the configured route
**ID:** `authenticated-model-routing`
The AI gateway SHALL return an OpenAI-compatible completion for an authorized request to the configured default model route.

#### Scenario: Client requests the default model
**ID:** `default-completion-round-trip`
- **WHEN** an authorized LAN client submits a bounded completion request for `default`
- **THEN** it receives a valid completion response through the configured upstream route

### Requirement: Real provider routing is explicitly verifiable
**ID:** `real-openrouter-routing`
An operator SHALL be able to run one bounded opt-in verification that routes through the AI gateway to its real configured provider.

#### Scenario: Operator selects live AI verification
**ID:** `bounded-live-request-succeeds`
- **WHEN** an operator explicitly runs the live AI profile with runtime credentials
- **THEN** the profile validates a real response without printing credentials or generated prose
