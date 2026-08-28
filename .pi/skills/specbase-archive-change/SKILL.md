---
name: specbase-archive-change
description: Archive a completed change in the experimental workflow. Use when the user wants to finalize and archive a change after implementation is complete.
allowed-tools: Bash(specbase:*)
license: MIT
compatibility: Requires specbase CLI.
metadata:
  author: specbase
  version: "1.0"
  generatedBy: "1.6.0"
---

Archive a completed change in the experimental workflow.

**Store selection:** If the user names a store (a store is a standalone Specbase repo registered on this machine) or the work lives in one, run `specbase store list --json` to discover registered store ids, then pass `--store <id>` on the commands that read or write specs and changes (`new change`, `status`, `instructions`, `list`, `show`, `validate`, `archive`, `doctor`, `context`). Other commands do not take the flag. Hints printed by commands already carry the flag; keep it on follow-ups. Without a store, commands act on the nearest local `specbase/` root.

**Input**: Optionally specify a change name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

1. **If no change name provided, prompt for selection**

   Run `specbase list --json` to get available changes. Use the **AskUserQuestion tool** to let the user select.

   Show only active changes (not already archived).
   Include the schema used for each change if available.

   **IMPORTANT**: Do NOT guess or auto-select a change. Always let the user choose.

2. **Check artifact completion status**

   Run `specbase status --change "<name>" --json` to check artifact completion.

   Parse the JSON to understand:
   - `schemaName`: The workflow being used
   - `planningHome`, `changeRoot`, `artifactPaths`, and `actionContext`: path and scope context
   - `artifacts`: List of artifacts with their status (`done` or other)

   **If any artifacts are not `done`:**
   - Display warning listing incomplete artifacts
   - Use **AskUserQuestion tool** to confirm user wants to proceed
   - Proceed if user confirms

3. **Check task completion status**

   Read the tasks file (typically `tasks.md`) to check for incomplete tasks.

   Count tasks marked with `- [ ]` (incomplete) vs `- [x]` (complete).

   **If incomplete tasks found:**
   - Display warning showing count of incomplete tasks
   - Use **AskUserQuestion tool** to confirm user wants to proceed
   - Proceed if user confirms

   **If no tasks file exists:** Proceed without task-related warning.

4. **Assess delta spec sync state**

   Use `artifactPaths.specs.existingOutputPaths` from status JSON to check for delta specs. If none exist, proceed without sync prompt.

   **If delta specs exist:**
   - Compare each delta spec with its corresponding main spec at `specbase/specs/<capability>/spec.md`
   - Determine what changes would be applied (adds, modifications, removals, renames)
   - Show a combined summary before prompting

   **Prompt options:**
   - If changes needed: "Sync now (recommended)", "Archive without syncing"
   - If already synced: "Archive now", "Sync anyway", "Cancel"

   If user chooses sync, use Task tool (subagent_type: "general-purpose", prompt: "Use Skill tool to invoke specbase-sync-specs for change '<name>'. Delta spec analysis: <include the analyzed delta spec summary>"). Proceed to archive regardless of choice.

5. **Perform the archive**

   Create an `archive` directory under `planningHome.changesDir` if it doesn't exist:
   ```bash
   mkdir -p "<planningHome.changesDir>/archive"
   ```

   Generate target name using current date: `YYYY-MM-DD-<change-name>`

   **Check if target already exists:**
   - If yes: Fail with error, suggest renaming existing archive or using different date
   - If no: Move `changeRoot` to the archive directory

   ```bash
   mv "<changeRoot>" "<planningHome.changesDir>/archive/YYYY-MM-DD-<name>"
   ```

6. **Display summary**

   Show archive completion summary including:
   - Change name
   - Schema that was used
   - Archive location
   - Whether specs were synced (if applicable)
   - Note about any warnings (incomplete artifacts/tasks)

**Output On Success**

```
## Archive Complete

**Change:** <change-name>
**Schema:** <schema-name>
**Archived to:** the archive path derived from `planningHome.changesDir`/YYYY-MM-DD-<name>/
**Specs:** ✓ Synced to main specs (or "No delta specs" or "Sync skipped")

All artifacts complete. All tasks complete.
```

**Guardrails**
- Always prompt for change selection if not provided
- Use artifact graph (specbase status --json) for completion checking
- Don't block archive on warnings - just inform and confirm
- Preserve .openspec.yaml when moving to archive (it moves with the directory)
- Show clear summary of what happened
- If sync is requested, use specbase-sync-specs approach (agent-driven)
- If delta specs exist, always run the sync assessment and show the combined summary before prompting

## Governed spec model

This project uses the governed spec model (5 permanent truth planes with paired enforcement). Do NOT assume the flat `specs/<capability>/spec.md` layout.

**Confirm the model from the CLI, do not guess:**
- Run `specbase status --change "<name>" --json` and read `specModel`.
- The governed model reports `specModel.kind == "governed"` with
  `planes: [service, estate, configuration, lifecycle, governance]` and `pairedEnforcement: true`.
- If `specModel.kind` is `legacy` (or absent), follow the flat-spec guidance
  above unchanged.

**Under the governed model, derive concrete paths from CLI output** (`status`
`artifactPaths` and `specbase instructions <artifact> --change ... --json`),
never hardcode them. Durable truth lives in the declared planes:
- service: Steady-state outcomes directly observed by people, administrators, devices, and client services: reachable capabilities, protocol results, authorization outcomes, errors, and externally meaningful state. (enforcement: protocol tests / property tests / bounded live probes / honest review) → `specs/service/<locator>/{spec.md,enforcement.yaml}`
- estate: The desired homelab graph: sites, hosts, roles, workload placement, dependencies, state ownership, authorities, trust boundaries, and failure domains. (enforcement: evaluated graph properties / reconciliation / topology review) → `specs/estate/<locator>/{spec.md,enforcement.yaml}`
- configuration: Proposal-worthy realization choices: selected products, versions, NixOS options, addresses, listeners, mounts, identities, groups, ACLs, schedules, and firewall realization. (enforcement: Nix evaluation / closure builds / VM composition / configuration audit) → `specs/configuration/<locator>/{spec.md,enforcement.yaml}`
- lifecycle: Durable guarantees whose meaning depends on time, an event, or a transition, including boot, deploy, update, rollback, revocation, backup, restore, failover, and recovery. (enforcement: transition tests / fault injection / bounded drills / manual evidence) → `specs/lifecycle/<locator>/{spec.md,enforcement.yaml}`
- governance: The repository and control machinery that declares, builds, tests, reviews, and deploys the estate, including Nix and IaC conventions, Specbase workflow, evidence quality, CI, operator tooling, and repo-owned agent instruments. (enforcement: deterministic conformance / mutation tests / semantic review) → `specs/governance/<locator>/{spec.md,enforcement.yaml}`

Every governed `spec.md` is PAIRED with an `enforcement.yaml`. Its binding values contain exactly `type`, requirement-level `covers`, and one `source`; the binding map key is its stable identity. Scenarios inherit coverage from their requirement. The resolved enforcement types are:
- test: Executable tests run by the project native test harness. (strength: automated; source: file)
- lint: Static lint rules run by the project native lint harness. (strength: automated; source: file)
- static-analysis: Deterministic structural analysis run by project tooling. (strength: automated; source: file)
- command: A project-owned executable conformance source. (strength: automated; source: file)
- review: Judgment performed through a configured review lens. (strength: review; source: lens)
- manual: A project-owned manual verification procedure. (strength: manual; source: file)

Stable identity is
scoped narrowly: the frontmatter `id` (e.g. `service.<locator>`) is the only project-unique governed ID; requirement, scenario, and binding `**ID:**` slugs are unique only within their pair, and stay fixed when titles or locators move.

**Plane classification:** match each proposed claim to the plane whose declared
purpose best fits the claim's nature. The shipped defaults are none; this project also declares service, estate, configuration, lifecycle, governance (read its purpose from the CLI). a single initiative may touch several planes — list one spec per plane touched, never mix planes in one spec.

**Structure conventions (governed):**
- Locators may nest to arbitrary safe depth (e.g. `service/platforms/desktop`);
  JSON reports normalized slash-separated locators, filesystem access is native.
- A directory that only GROUPS child pairs is a **namespace** and needs no pair of
  its own. Only a directory that contains `spec.md` must also contain
  `enforcement.yaml`; ancestry provides navigation, never inherited requirements.
- A change stores its `spec.md` and `enforcement.yaml` deltas under the SAME
  plane-qualified locator as the target current pair, so both members move together.

### Authoring rules (governed)

These rules travel with this skill; apply them whenever you place or write a
governed pair. They are the current text of this project's clean manifestos.

**Placement - where a pair belongs:**

Placing a governed pair in the spec tree:

- Treat planes as peers, never as layers. Each plane answers to a different
  actor, on its own clock.
- Apply the actor test: put two requirements in the same plane only if the same
  actor would demand their revision. When the plane is ambiguous, ask who shows
  up angry when the requirement breaks.
- Give every fact exactly one home locator. Let other planes reference it by
  locator; never let them restate it.
- Expect co-change: one feature may legitimately land deltas in several planes.
- Forbid coupled change: editing one plane's text must never force an edit to
  another's.
- Apply the swap test: swapping a vendor, version, or runtime setting while
  preserving outcomes and topology touches Configuration only.
- Treat depth as volatility. A leaf refines its ancestors; a parent never
  depends on a leaf.
- Let ripple flow leafward. A parent edit may ripple to its leaves; a leaf edit
  must never force an ancestor edit.
- Keep every node open-closed. Adding a leaf must touch nothing above it. A
  parent that lists its children has a reverse dependency.
- Inherit nothing. Ancestry provides navigation only; parent and leaf bind
  independently, and a conflict between them is a defect, not a precedence
  question.
- Place each requirement at the depth that matches how far you intend its
  changes to ripple.
- Hoist on duplication. Promote a requirement to the parent only when two or
  more siblings would otherwise duplicate it. Leave specifics at the leaf.
- Quantify to place. "Every X SHALL…" is a parent claim; enforce it by one
  conformance test over the registry, not by per-child assertions.
- Grant no leaf exemptions. If one leaf cannot satisfy a parent invariant,
  narrow the parent; never special-case the leaf.
- Earn parents. Default an intermediate directory to a pure namespace with no
  `spec.md`, and create the pair only when siblings actually share invariants.
- Earn depth. Flatten an intermediate node that has no pair and no plausible
  one.

Reject these placement smells: leaked fact, restated truth across planes, churny
parent, enumerating parent, speculative parent, leaf exemption.

**Writing - what one pair says:**

Writing one governed spec pair (`spec.md` + `enforcement.yaml`):

- State only current, verifiable truth. Write WHAT the system promises, never
  HOW the code delivers it. Delete mechanism narration.
- Give every candidate requirement a verdict: keep durable truth, move a real
  topology, placement, dependency, authority, ownership, boundary, or failure-domain
  invariant to Estate, demote code narration to design docs, and drop superseded truth.
- Make one claim per requirement. Split a compound requirement.
- Use SHALL, name the actor, and state an observable outcome in active voice.
- Write every claim so a check could fail it. If no check can fail the claim,
  rewrite it or demote it.
- Put a universal claim ("every command SHALL…") at a parent locator.
- Write scenarios as examples, not enumeration. The requirement owns the claim;
  cover the representative case, the edge case, and the risky case.
- Keep foreign facts out. Name the role ("the telemetry backend"), never the
  vendor another plane owns.
- Reference a foreign truth by its locator and never restate its content. A
  restated truth is a future lie.
- Bind checks at the requirement level, not per scenario.
- Prefer the highest-leverage check. One fitness function or property test beats
  many example tests.
- Select a type from the resolved project roster and keep each binding to exactly
  `type`, requirement-level `covers`, and one `source`.
- Keep source behavior, harness details, failure signals, and known boundaries in
  planning artifacts and the source itself.
- Report structural linkage, native-harness execution, and semantic
  correspondence separately.
- Never write a test to inflate coverage. `degraded` is a fact, not a failure.

Reject these writing smells: mechanism narration, untestable claim, compound
claim, enumerated scenarios, foreign fact, restated truth, hollow binding,
per-scenario binding.

### Archiving a governed change (governed)

Require complete pairs, valid requirement-level coverage, resolved types and sources, and recorded native-harness results before archive. Promote `spec.md` with compact `enforcement.yaml` as one unit. A validation bypass is explicit and unverified. Report retired unshared file sources as cleanup candidates without deleting them.
