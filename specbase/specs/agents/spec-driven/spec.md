---
id: agents.spec-driven
---

<!--
  Planted by `openspec init` (governed model) as bootstrap scaffolding, NOT
  through the change flow. It is the repo's self-hosting spec: it declares that
  this repository practices spec-driven development via opsx, and describes the
  agent-operational artifact that governs it - openspec/config.yaml - asserting
  the config conforms rather than generating it. Edit this spec through a change,
  not by re-running init.
-->

## ADDED Requirements

### Requirement: Repository practices spec-driven development via opsx
**ID:** practices-sdd
This repository SHALL practice spec-driven development using the opsx workflow,
and `openspec/config.yaml` SHALL declare the governed schema and the resolved
plane roster the repository works to. The config is the runtime source of truth;
this spec describes it and asserts conformance.

#### Scenario: Governed schema is declared
**ID:** governed-schema-declared
- **WHEN** enforcement inspects `openspec/config.yaml`
- **THEN** it finds `schema: spec-driven-governed` and a resolved plane roster

#### Scenario: The project validates
**ID:** project-validates
- **WHEN** `openspec validate` runs against this repository
- **THEN** it exits successfully, confirming the governed workflow is well-formed
