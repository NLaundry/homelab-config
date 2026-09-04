## 1. Replace the Estate implementation

- [x] 1.1 Add the single `estate.yaml` inventory with the current site, NAS host details, address, storage pools, and file-sharing service placement.
- [x] 1.2 Add `make estate-check` as the obvious focused command for inventory edits.
- [x] 1.3 Remove `nix/estate/`, Estate graph exports/checks, reconciliation mutants, and generated graph artifacts from the flake.

## 2. Deliver minimal inventory evidence

- [x] 2.1 Replace `tests/estate/registry.bats` with one focused `tests/estate/inventory.bats` source that checks YAML shape, references, and current values through the native harness.
- [x] 2.2 Update direct-observation declarations and paired enforcement bindings for the inventory source.
- [x] 2.3 Remove retired graph/reconciliation observation declarations and the current registry-review evidence record after confirming no surviving binding uses them.
- [x] 2.4 Execute `make estate-check` and the routine non-live harness and record the results.

## 3. Validate the simplification

- [x] 3.1 Run strict projected-change validation and confirm every new binding resolves with direct observation declarations; current-tree validation follows the atomic archive.
- [x] 3.2 Run all-system flake evaluation and the non-live harness; the full current-tree project test follows the atomic archive.
- [x] 3.3 Review the focused diff for simplicity, verify the running NAS configuration is unchanged, and record rollback guidance.
