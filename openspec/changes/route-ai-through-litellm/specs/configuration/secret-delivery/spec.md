---
id: configuration.secret-delivery
---

## ADDED Requirements

### Requirement: The guest receives read-only service secret files
**ID:** `gateway-secret-delivery`
The AI guest SHALL receive each rendered service environment through a dedicated read-only runtime file.

#### Scenario: Guest secret mounts are inspected
**ID:** `guest-secret-files-are-read-only`
- **WHEN** the guest mounts the host-rendered service environments
- **THEN** the guest can read each file but cannot modify the host copy

### Requirement: Secret delivery is least-scoped
**ID:** `gateway-secret-scope`
Each AI service SHALL receive only the credentials that service consumes.

#### Scenario: Service runtime environments are enumerated
**ID:** `unrelated-secrets-are-absent`
- **WHEN** each service's rendered secret keys are enumerated without reading their values
- **THEN** no unrelated host or service credential is present
