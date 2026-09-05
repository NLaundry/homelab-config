## Context

The repository was migrated from OpenSpec naming and paths to Specbase, but the planted agents pairs were not migrated with it. Coverage reports both pairs broken because their active bindings target `openspec/config.yaml`; the spec-driven pair also invokes the old CLI. The review-panel pair additionally describes a lens-per-plane rule that does not match the repo-owned skill's explicit reviewed lens roster.

During implementation, strict validation exposed a schema-wide compatibility issue: all other current pairs still use legacy Markdown enforcement whose bindings cover scenario IDs, while compact governed enforcement accepts requirement IDs only. Repairing only the agents pairs would therefore leave project-wide strict validation red. This change now performs the mechanical compact migration for every current pair while preserving normative contracts and binding identities.

## Goals / Non-Goals

**Goals:**

- Make both planted agent-instrument pairs describe current runtime artifacts.
- Preserve stable IDs while replacing stale product names, paths, and commands.
- Make strict project validation and coverage free of broken agent targets and hanging claims.
- Check the review panel's actual declared lens table rather than asserting an inferred roster.
- Migrate all current enforcement members to compact requirement-level YAML so strict project validation is coherent.

**Non-Goals:**

- Redesign the Specbase schema or plane roster.
- Add a new agents review lens.
- Change the behavior of ordinary homelab code or testing runners.
- Redesign existing non-agent normative requirements or claim that live manual checks became automated.

## Decisions

### Treat the current files as instrument sources of truth

`specbase/config.yaml` is the workflow configuration target. `.pi/skills/specbase-review-panel/SKILL.md` is the repo-owned review-panel artifact. The specs describe these files and never generate them.

### Use one deterministic conformance script

A small script under `tests/agents/` will assert the configured schema and plane IDs, invoke strict Specbase spec validation, inspect the review-panel lens table, and compare it with the lens set reported by coverage. This provides stronger evidence than grepping one stale path while keeping all checks in one self-hosting fitness function.

The review-panel binding remains review-strength for the semantic quality of lens questions, while the script owns deterministic roster/path conformance. This avoids claiming that string equality proves review quality.

### Preserve identity through the migration

Spec IDs and all requirement/scenario IDs remain unchanged. Binding IDs are retained where their meaning survives and replaced in place; obsolete OpenSpec-only bindings are removed explicitly.

### Keep compact indexes declarative and evidence executable

Compact indexes cover requirement IDs only; their scenarios inherit coverage. Existing automated commands move into selector-addressable `tests/specbase/current-bindings.sh`, manual procedures move into `tests/specbase/manual-verification.md`, and the Samba judgment residue names the configured `behavioural` lens. This preserves evidence strength without embedding obsolete execution schemas in enforcement indexes.

## Risks / Trade-offs

- **Specbase validation includes the pair being repaired** -> Stage the config/lens assertions first, then run strict validation after all targets and deltas exist.
- **A text parser of the Markdown lens table could be brittle** -> Parse only stable lens identifiers and scopes, with an actionable failure when the table format changes.
- **Coverage may report semantic lens issues beyond stale paths** -> Surface them rather than weakening the check; split a later change if a new instrument behavior is required.
- **Mechanical migration could exaggerate old evidence** -> Preserve each binding's prior strength, keep live checks manual or explicitly environment-dependent, and execute every workstation-safe selector before promotion.

## Migration Plan

1. Add the instrument conformance script against current paths.
2. Update the two agents specs and enforcement bindings from OpenSpec to Specbase.
3. Move legacy command and manual implementation details into project-owned shared sources.
4. Migrate every current pair to compact requirement-level enforcement while preserving normative and binding IDs.
5. Run all workstation-safe source selectors, strict spec validation, and coverage against a simulated archive.
6. Remove only bindings that refer exclusively to retired OpenSpec artifacts.
7. Archive this change before enabling the `make lint` dependency in the testing-operations stack.
