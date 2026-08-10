# Enforcement: The review panel judges every governed plane

Paired with `spec.md` (`agents.review-panel`). The default binding is a **review**
binding: in a consuming project the review panel is the lens set OpenSpec applies
over the project's specs, which the project does not own as code — so agentic
review is honestly review-strength evidence, not a project-owned test.

A repository that OWNS the panel (its own lens set in code) should REPLACE this
binding with an automated `test` one asserting the resolved lens set conforms to
the lenses this spec declares — e.g. OpenSpec itself binds `lens-conformance` to
a vitest over `src/core/governed/lenses.ts`.

```yaml
version: 1
spec: agents.review-panel
bindings:
  - id: panel-review
    covers: [panel-covers-planes, lens-per-plane, lenses-conform]
    mechanism: review
    strength: review
    status: active
    targets:
      - openspec/config.yaml
    review:
      procedure: >-
        Confirm the review panel provides one non-cross-cutting lens per governed
        plane the project resolves (plus the cross-cutting enforcement lens), and
        that the lens set matches the lenses declared in this spec.
      inputs:
        - openspec/config.yaml
        - openspec/specs/agents/review-panel/spec.md
    limitations: A review confirms the lens set by inspection, not by an automated conformance check.
```
