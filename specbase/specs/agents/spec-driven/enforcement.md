# Enforcement: Repository practices spec-driven development via opsx

Paired with `spec.md` (`agents.spec-driven`). The governed workflow's own CLI is
the enforcement instrument: `openspec validate` proves the workflow is well-formed,
and a config check proves the declared roster matches what the spec asserts.

```yaml
version: 1
spec: agents.spec-driven
bindings:
  - id: openspec-validates
    covers: [practices-sdd, project-validates]
    mechanism: command
    strength: automated
    status: active
    targets:
      - openspec/config.yaml
    run:
      command: openspec
      args: [validate, --strict]
      cwd: .
    limitations: Proves the workflow is well-formed, not that every spec is materially correct.

  - id: governed-schema-declared
    covers: [governed-schema-declared]
    mechanism: command
    strength: automated
    status: active
    targets:
      - openspec/config.yaml
    run:
      command: openspec
      args: [config, --json]
      cwd: .
    limitations: Confirms the declared schema and roster; does not judge whether the roster is the right one.
```
