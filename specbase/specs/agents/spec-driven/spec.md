---
id: agents.spec-driven
---

## Purpose
This pair keeps the repository's spec-driven workflow instrument aligned with the Specbase configuration and CLI that agents and operators actually use.

## ADDED Requirements

### Requirement: Repository practices spec-driven development via Specbase
**ID:** `practices-sdd`
This repository SHALL practice spec-driven development using the Specbase `spcb` workflow, and `specbase/config.yaml` SHALL declare the governed schema and resolved plane roster. The configuration is the runtime source of truth; this spec describes it and requires the instrument to conform to it.

#### Scenario: Governed schema is declared
**ID:** `governed-schema-declared`
- **WHEN** enforcement inspects `specbase/config.yaml`
- **THEN** it finds `schema: spec-driven-governed` and the resolved plane roster

#### Scenario: The project validates
**ID:** `project-validates`
- **WHEN** strict Specbase validation runs against all current specifications
- **THEN** it exits successfully, confirming the governed workflow is structurally well-formed
