## Context

`nixos-rebuild` can exit successfully while services fail immediately afterward or the host becomes unreachable. The deployment pair currently records a manual SSH procedure, while the testing-operations stack establishes Bats and `make verify` for live evidence.

## Goals / Non-Goals

**Goals:**

- Define a small deployment-scoped smoke profile.
- Verify reachability, systemd health, and an active NixOS system generation after activation.
- Propagate verification failure without pretending rollback occurred.
- Leave service-specific behavior in its owning pairs.

**Non-Goals:**

- Add automatic rollback.
- Duplicate Samba, ZFS, or operator capability assertions.
- Prove boot persistence without rebooting.
- Require exact closure identity unless the deploy process exposes the expected path reliably.

## Decisions

### Add a deployment-tagged Bats profile

`tests/verify/deployment.bats` runs from the operator environment and is selectable through `make verify`. It waits boundedly for SSH, checks `systemctl --failed --quiet`, and asserts `/run/current-system` resolves beneath `/nix/store` to an existing system closure.

The top-level file joins the default suite, so successful `make try` and `make deploy` activations run it automatically. The operator may also run `make verify` at any later time as a smoke check.

### Keep identity claims conditional on available evidence

If implementation can capture the built toplevel path from the deployment command without rebuilding or parsing unstable output, the test compares it with `/run/current-system`. Otherwise it prints the active path and proves structural validity only; the permanent requirement does not overclaim exact identity.

### Fail closed without rollback claims

Any selected smoke failure returns non-zero and identifies the condition. The deployed generation remains active until the operator chooses rollback or another activation. Documentation states that distinction prominently.

### Preserve ownership boundaries

Deployment smoke confirms generic host viability. Samba transactions, operator authorization semantics, and pool health stay in their behavioral test files even when `make verify` can run all tags together.

## Risks / Trade-offs

- **SSH readiness races activation** -> Poll with a finite timeout and capture the final SSH diagnostic.
- **A failed optional unit makes verification noisy** -> Treat systemd's failed set as operational failure; add an explicit service exception through a future spec rather than silently filtering it.
- **The active path check is weaker than closure equality** -> State the limitation until the deploy wrapper provides expected-path evidence.

## Migration Plan

1. Land testing operations and test-quality prerequisites.
2. Add the deployment-tagged Bats checks and controlled failure fixtures.
3. Update deployment documentation to describe the automatically invoked deployment health check and no-rollback failure state.
4. Replace manual-only deployment success evidence after live checks pass.
5. Validate the rebased `ops.deployment` pair against current automatic post-activation semantics.
