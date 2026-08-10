## 1. Spec pairs: author the governed deltas

- [x] 1.1 Author `specs/behavior/storage/nas-boot/{spec,enforcement}.md`
- [x] 1.2 Author `specs/behavior/storage/nas-users/{spec,enforcement}.md`
- [x] 1.3 Author `specs/behavior/storage/nas-utility-packages/{spec,enforcement}.md`
- [x] 1.4 Author `specs/architecture/flake-entry/{spec,enforcement}.md`
- [x] 1.5 Author `specs/architecture/host-modules/{spec,enforcement}.md`
- [x] 1.6 Author `specs/ops/deployment/{spec,enforcement}.md`
- [x] 1.7 Author `specs/ops/nixpkgs-pin/{spec,enforcement}.md`

## 2. Evidence: confirm every binding's target exists (this is a spec-only refactor — no new code)

The deployed NAS, flake, modules, and Makefile are unchanged; every `active`
binding targets an existing repo file or installed tool. Confirm each:

- [x] 2.1 `nix` is on PATH on the workstation (covers the `command`/`nix eval`/`nix flake check` bindings across behavior, architecture, ops)
- [x] 2.2 `make` is on PATH (covers `make -n` / `grep` bindings in `ops.deployment`)
- [x] 2.3 `git` is on PATH (covers the `git ls-files --error-unmatch flake.lock` binding in `ops.nixpkgs-pin`)
- [x] 2.4 Repo files named as targets exist: `flake.nix`, `hosts/nas/default.nix`, `hosts/nas/zfs.nix`, `Makefile`, `flake.lock`
- [x] 2.5 Spot-run a representative binding: `nix eval .#nixosConfigurations.nas.config.boot.zfs.extraPools` resolves to the declared pools (verified via `--json` → `["smolBoy","mediaBin"]`; the `--raw` flag cannot coerce a list)
- [x] 2.6 Spot-run a representative binding: `make -n deploy` expands to a `nixos-rebuild ... --target-host ... --build-host ... switch` line
- [x] 2.7 Note the three `manual` bindings (`pools-import-on-boot-runtime`, `operator-ssh-sudo-runtime`, `deploy-succeeds-runtime`) require the box and are honestly `manual` — no action to make them `active` beyond their existing targets

## 3. Re-home the historical archive and retire the legacy layout

- [x] 3.1 `git mv openspec-old/changes/archive/2026-08-06-flakify-nas openspec/changes/archive/2026-08-06-flakify-nas` (verbatim; keep its legacy `.openspec.yaml` `schema: spec-driven` and flat `specs/nixos-deploy/spec.md` delta as a historical snapshot — do not rewrite into governed form) — (src was untracked, so used a plain `mv` of identical content)
- [x] 3.2 Delete `openspec-old/` (its durable content is now the governed pairs; its archive is re-homed in 3.1)
- [x] 3.3 Fix the stale `README.md` reference: `openspec/changes/flakify-nas/design.md` → `openspec/changes/archive/2026-08-06-flakify-nas/design.md`

## 4. Verify the governed workflow is well-formed

- [x] 4.1 `openspec validate "migrate-to-governed-specs" --strict` passes (specs + enforcement pairs valid)
- [x] 4.2 `openspec coverage --json` shows the new pairs across behavior, architecture, and ops (agents untouched; no hanging requirements)
- [x] 4.3 `openspec status --change "migrate-to-governed-specs"` reports all `applyRequires` artifacts done

## 5. Archive the change (apply deltas to permanent specs)

- [x] 5.1 `openspec archive "migrate-to-governed-specs"` — moves the deltas into `openspec/specs/` and the change into `openspec/changes/archive/`
- [x] 5.2 Post-archive `openspec coverage --json` confirms the 7 new pairs are live (plus the 2 existing agents pairs = 9 total), no orphans
