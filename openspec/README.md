# Planning

Use OpenSpec for substantial changes. Small fixes can use a short chat plan.

- `specs/`: current specifications.
- `changes/`: active plans and archived history.
- `ideas/`: early notes. OpenSpec does not manage this folder.
- `stacks/`: ordered groups of changes. OpenSpec does not manage this folder.

## Commands

Install the OpenSpec CLI separately. In Pi, use `/opsx-propose`, `/opsx-apply`,
and `/opsx-archive`. Use `/opsx-explore` to discuss an idea without implementing it.

```sh
openspec list
openspec list --specs
openspec validate --all --strict
```

## Stack order

Follow each `stack.yaml` member list from top to bottom. Match member IDs to
change `.openspec.yaml` files. Completed members live in `changes/archive/`.
Do not apply or archive a later member before its prerequisites exist.

## Imported plans

The migration preserved spec text, ideas, stacks, and change plans. It removed
active enforcement manifests. Archived files remain unchanged.

Some imported text describes retired Specbase commands, old paths, or deleted
checks. Treat that material as historical context. Reconcile a plan with the
current Makefile and agent guidance before applying it. Do not recreate the
removed machinery or treat old evidence as proof of current behavior.
