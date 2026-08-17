---
id: ops.repository-operations
---

### Requirement: The root Makefile exposes registered operations
**ID:** `makefile-operation-surface`
The root `Makefile` SHALL declare an operation registry and SHALL expose every registered operation as a documented, same-named phony target.

#### Scenario: An operator invokes a registered operation
**ID:** `declared-operation-dispatched`
- **WHEN** an operator runs `make <operation>` for an operation in the registry
- **THEN** the root `Makefile` dispatches that operation through its same-named target
