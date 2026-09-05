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

## History and limits

Current specs and active plans no longer require the retired Specbase workflow,
enforcement manifests, or test registries. Archived changes remain unchanged.

Old progress records and ideas may still describe removed commands or checks.
Treat them as history, not current instructions or proof of working behavior.
The network secret foundation must be reconciled with the deferred AI secret
plan before that plan is implemented.
