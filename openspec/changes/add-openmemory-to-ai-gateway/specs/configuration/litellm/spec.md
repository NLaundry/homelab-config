---
id: configuration.litellm
---

## ADDED Requirements

### Requirement: The memory embedding alias uses the selected embedding model
**ID:** `openrouter-memory-embedding`
LiteLLM SHALL map the `memory-embedding` alias to `openrouter/openai/text-embedding-3-small`.

#### Scenario: Memory embedding is requested
**ID:** `embedding-alias-selects-model`
- **WHEN** the memory service requests an embedding for `memory-embedding`
- **THEN** LiteLLM selects the configured OpenRouter embedding route
