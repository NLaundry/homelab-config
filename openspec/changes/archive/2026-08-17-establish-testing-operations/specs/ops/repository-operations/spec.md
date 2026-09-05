---
id: ops.repository-operations
---

## Purpose

The repository gives operators one stable entry point for recurring lifecycle work while focused Ops pairs define which operations exist and what each operation does.

## ADDED Requirements

### Requirement: The root Makefile exposes registered operations
**ID:** `makefile-operation-surface`
The root `Makefile` SHALL declare an operation registry and SHALL expose every registered operation as a documented, same-named phony target.

#### Scenario: An operator invokes a registered operation
**ID:** `declared-operation-dispatched`
- **WHEN** an operator runs `make <operation>` for an operation in the registry
- **THEN** the root `Makefile` dispatches that operation through its same-named target
