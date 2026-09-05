---
id: lifecycle.ai-gateway
---

## MODIFIED Requirements

### Requirement: Failed AI services restart
**ID:** `failed-service-restart`
The `ai-gateway` service manager SHALL restart a declared AI service after an unexpected process failure.

#### Scenario: AI service process is terminated
**ID:** `service-recovers-after-failure`
- **WHEN** an AI service exits unexpectedly
- **THEN** the service manager returns it to a healthy state within the bounded restart window

#### Scenario: LongMemory process is terminated
**ID:** `openmemory-recovers-after-failure`
- **WHEN** LongMemory exits unexpectedly
- **THEN** the service manager returns it to a healthy state within the bounded restart window

### Requirement: Unhealthy guest activation is visible
**ID:** `activation-health`
A deployment verification SHALL fail when the guest boots but a required enabled AI service does not become ready.

#### Scenario: Required service remains unhealthy
**ID:** `unhealthy-service-fails-verification`
- **WHEN** an enabled AI service misses its readiness deadline after activation
- **THEN** deployment verification reports the failing guest service and exits non-zero

#### Scenario: Enabled LongMemory remains unhealthy
**ID:** `unhealthy-openmemory-fails-verification`
- **WHEN** LongMemory is enabled but misses its readiness deadline after activation
- **THEN** default deployment verification reports LongMemory and exits non-zero without making a provider request
