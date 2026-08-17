## Why

The planted agent-instrument pairs still describe the former OpenSpec names and target `openspec/config.yaml`, which no longer exists. Their broken bindings make strict project validation fail and would make the proposed `make lint` gate unusable.

## What Changes

- Update the spec-driven instrument contract from OpenSpec/opsx terminology to Specbase/spcb and `specbase/config.yaml`.
- Update its automated bindings to run the current Specbase CLI against current targets.
- Update the review-panel binding inputs and targets to current Specbase paths and the repo-owned review-panel skill.
- Add missing Purpose sections while preserving stable spec, requirement, scenario, and binding IDs.
- Migrate every current legacy Markdown enforcement member to the compact requirement-level YAML index required by the governed schema.
- Preserve executable and manual evidence in project-owned sources rather than embedding execution details in compact indexes.
- Confirm strict project validation and coverage no longer report stale bindings, broken targets, hanging claims, or uncovered scenarios.

## Planes

### Agents

- `agents.spec-driven`: the repository's Specbase workflow instrument and its configuration conformance checks (modified).
- `agents.review-panel`: the repo-owned review-panel instrument and its resolved-lens review evidence (modified).

### Architecture

- `architecture.flake-entry` and `architecture.host-modules`: compact migration of existing fitness-function bindings.

### Behavior

- Existing NAS boot, Samba, user-access, and utility-package pairs: compact migration without changing their normative contracts.

### Ops

- Existing deployment and nixpkgs-pin pairs: compact migration without changing their normative contracts.

## Spec pairs

- `agents.spec-driven` -> paired enforcement via `specbase validate` and configuration inspection commands.
- `agents.review-panel` -> paired enforcement via a named review procedure over the resolved coverage lens set and repo-owned skill.

## Impact

- Repairs the two planted agents pairs and migrates all eight remaining current pairs from legacy enforcement Markdown to compact YAML.
- Adds shared executable and manual evidence sources under `tests/specbase/` while preserving existing binding identities and evidence intent.
- Removes stale OpenSpec terminology and paths without changing the project's plane roster or normative homelab behavior.
- Unblocks `establish-testing-operations`, whose `make lint` stage requires strict Specbase validation to pass.
