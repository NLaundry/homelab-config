---
id: lifecycle.ai-gateway
---

## Purpose

The AI guest starts with NASty after its production network prerequisite becomes available.

## ADDED Requirements

### Requirement: The AI guest starts during NASty boot
**ID:** `guest-autostart`
NASty SHALL start `ai-gateway` after its network prerequisite becomes available.

#### Scenario: NASty reaches multi-user operation
**ID:** `guest-starts-after-prerequisites`
- **WHEN** NASty boots with valid AI gateway configuration
- **THEN** the guest starts after its declared network prerequisite without manual intervention
