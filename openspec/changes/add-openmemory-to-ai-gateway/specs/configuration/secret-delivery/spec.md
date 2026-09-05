---
id: configuration.secret-delivery
---

## MODIFIED Requirements

### Requirement: The guest receives read-only service secret files
**ID:** `gateway-secret-delivery`
The AI guest SHALL receive each rendered service environment through a dedicated read-only runtime file.

#### Scenario: Guest secret mounts are inspected
**ID:** `guest-secret-files-are-read-only`
- **WHEN** the guest mounts the host-rendered service environments
- **THEN** the guest can read each file but cannot modify the host copy

#### Scenario: OpenMemory secret mount is inspected
**ID:** `openmemory-secret-file-is-read-only`
- **WHEN** the guest mounts the host-rendered OpenMemory environment
- **THEN** LongMemory can read the dedicated file but cannot modify the host copy

### Requirement: Secret delivery is least-scoped
**ID:** `gateway-secret-scope`
Each AI service SHALL receive only the credentials that service consumes.

#### Scenario: Service runtime environments are enumerated
**ID:** `unrelated-secrets-are-absent`
- **WHEN** each service's rendered secret keys are enumerated without reading their values
- **THEN** no unrelated host or service credential is present

#### Scenario: OpenMemory runtime environment is enumerated
**ID:** `openmemory-unrelated-secrets-are-absent`
- **WHEN** the OpenMemory service file's keys are enumerated without reading their values
- **THEN** only `LONGMEMORY_API_KEY` and `OPENAI_API_KEY` are present and `OPENROUTER_API_KEY` is absent
