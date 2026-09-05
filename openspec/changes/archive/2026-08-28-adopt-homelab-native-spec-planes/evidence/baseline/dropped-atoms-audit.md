# Dropped and demoted atom audit

Captured before the plane cutover.

| Atom | Current binding/source | Other binding users | Disposition |
|---|---|---|---|
| Utility package presence | `utility-packages-eval` → `tests/specbase/current-bindings.sh#utility-packages-eval` | None | Retire the binding and assertion case; leave the ordinary Nix package configuration unchanged. |
| Forced-import warning wording | `eval-no-force-import-root-warning` → `tests/specbase/current-bindings.sh#eval-no-force-import-root-warning` | None | Retire the warning-text binding/case; retain evaluated `boot.zfs.forceImportRoot = false` evidence through `config-intent`. |
| Make target/help existence | `makefile-operation-surface-conforms` → `tests/harness/make-operation-surface.bats` | None | Retire the binding; retain the Makefile and harness only if another non-Specbase project test intentionally uses them. |
| Unspecified update cadence | No distinct binding; prose atom inside `ops.nixpkgs-pin#nixpkgs-release-pinned` | The lock, release, and evaluation bindings prove reproducibility but do not prove cadence | Drop only the cadence clause. Retain lock-resolution, release/state-version consistency, and host-evaluation evidence. |

No surviving governed requirement depends on the first three retired targets. The pin evidence targets remain because they establish the surviving reproducibility claim, not the dropped cadence atom.
