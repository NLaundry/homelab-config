---
id: service.ai-gateway
---

## ADDED Requirements

### Requirement: Authorized embedding requests use the configured route
**ID:** `authenticated-embedding-routing`
The AI gateway SHALL return an OpenAI-compatible embedding for an authorized request to the configured memory embedding route.

#### Scenario: Memory service requests an embedding
**ID:** `embedding-round-trip`
- **WHEN** an authorized guest-local client requests `memory-embedding`
- **THEN** it receives a numeric embedding from the configured upstream route
