# Test-quality advisory exercise — 2026-08-17

## Enforcement lens

The lens compared the current `smbutil-view-wire` binding with the controlled non-live phase-registry regression.

- `smbutil-view-wire` reaches the real deployed SMB path, so it passes `production-path-fidelity` and does not copy production logic.
- It fails `defect-sensitive-assertions`: command success does not assert that both `mediaBin` and `smolBoy` are present. This is a missing/partial oracle rather than a self-fulfilling one. The planned Samba hardening change owns its replacement.
- A controlled copied-logic example that reimplements share-selection rules inside its fixture fails `production-path-fidelity` even if its assertions pass, because no responsible production artifact is exercised.
- A controlled self-fulfilling example that obtains both `expected` and `actual` from the same evaluated option fails `defect-sensitive-assertions`; changing that shared source changes both sides and preserves a false green.
- The phase-registry fixture passes both policies. It obtains the observed registry from Make, keeps an independent expected inventory, deletes `tooling` in a controlled copy, and requires the checker to fail. Companion cases in the same bound source exercise dispatch and failure propagation.

## Code-quality lens

The lens exercised the hygiene rules over current sources and controlled counterexamples.

- `tests/harness/nixos-vm.nix` passes bounded condition synchronization, run isolation, order independence, and diagnostics: it uses the test-driver deadline, waits for `multi-user.target`, and preserves exact guest commands. Live cleanup/residue rules are not applicable to disposable guests.
- `tests/harness/test-operation.bats` passes run scoping and order independence through per-test `mktemp` setup and teardown. Its independent inventory helper has actionable expected/actual output; several older bare status/grep assertions provide weaker diagnostics and remain prospective hardening rather than scope for this policy-only change.
- A fixed sleep before a protocol assertion fails `condition-based-synchronization`.
- A shared `/tmp/fixed` fixture fails `run-scoped-state` and fails order independence when prior residue affects the verdict.
- Teardown that executes but replaces the original assertion failure fails `live-cleanup-preserves-failure`; teardown that never executes after a supported failure fails `failure-safe-live-cleanup`.
- Cleanup residue that leaves the test green fails `residual-state-visible`. A failed cleanup that omits the exact resource fails `residual-resource-identified` and `failure-context-preserved`.
- A remote failure that does not name the intended governed outcome fails `actionable-test-failures`; one that names the outcome but drops command or transport evidence fails `failure-context-preserved`.

Both exercises were advisory. They changed no product or test source and produced no validation gate.
