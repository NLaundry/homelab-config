## Why

`make try` and `make deploy` now invoke the default live suite automatically, but that suite has no generic deployment-health check. A focused source must establish that the activated NAS generation is reachable and operational before an operator treats the deployment as verified.

## What Changes

- Add deployment health to the default `make verify` suite that already runs automatically after successful `make try` and `make deploy` activation.
- Add a focused Bats deployment test that confirms SSH reachability, no failed systemd units, and a valid active `/run/current-system` generation.
- Where the deployment command exposes the expected closure, compare it to the active generation; otherwise report the active generation explicitly without making a false identity claim.
- Keep service-specific checks bound to their own behavioral pairs rather than duplicating Samba, user, or ZFS assertions in deployment enforcement.
- Replace the manual-only deployment-success binding after the automated live check is active, retaining manual reboot/persistence evidence where necessary.

## Planes

### Ops

- `ops.deployment`: operational criteria and evidence for a successfully activated remote deployment (modified).

## Spec pairs

- `ops.deployment` -> paired enforcement via the current deployment-operation conformance source and a live Bats post-activation health test.

## Impact

- Adds a deployment-focused Bats file consumed by `make verify`.
- Builds on the archived testing-operations contract, including automatic post-activation verification and explicit no-rollback failure semantics.
- Uses the archived test-quality policy for the new live source.
- Does not automatically roll back a failed deployment in this change.
