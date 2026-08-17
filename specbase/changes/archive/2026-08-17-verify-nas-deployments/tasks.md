## 1. Deployment smoke behavior

- [x] 1.1 Rebase this change after the archived testing-operations and test-quality prerequisites so automatic post-activation verification, no-rollback semantics, and advisory test review are current.
- [x] 1.2 Add `tests/verify/deployment.bats` with the `deployment` tag and an inventory-derived NAS endpoint.
- [x] 1.3 Implement bounded SSH readiness, `systemctl --failed --quiet`, and `/run/current-system` resolution/existence assertions with distinct diagnostics.
- [x] 1.4 If the deploy wrapper can expose the expected toplevel path reliably, compare it with the active path; otherwise print the active path and preserve the documented limitation.
- [x] 1.5 Confirm the deployment profile does not duplicate Samba transactions, operator authorization semantics, or ZFS pool assertions.

## 2. Workflow integration

- [x] 2.1 Document that the default deployment health check runs automatically after both `make try` and `make deploy`, and that failure does not perform rollback.
- [x] 2.2 Add controlled fixtures proving unreachable SSH, a failed unit, and an invalid current-system link each fail with an actionable check name.
- [x] 2.3 Preserve the current independently runnable, non-activating `make verify` operation.

## 3. Paired evidence and cleanup

- [x] 3.1 Run the deployment profile after a temporary activation and a persistent deployment during an approved test window.
- [x] 3.2 Confirm the compact `deploy-live-verification` binding is complete after its live source and failure fixtures pass.
- [x] 3.3 Retain the manual `deploy-succeeds-runtime` binding for the end-to-end build/activation mechanism while scoping `deploy-live-verification` to post-activation health.
- [x] 3.4 Run strict validation against the rebased stacked pair, inspect merged coverage, and run the changed-tests quality review.
