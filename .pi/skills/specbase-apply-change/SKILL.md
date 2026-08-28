---
name: specbase-apply-change
description: Implement tasks from a Specbase change. Use when the user wants to start implementing, continue implementation, or work through tasks.
allowed-tools: Bash(specbase:*)
license: MIT
compatibility: Requires specbase CLI.
metadata:
  author: specbase
  version: "1.0"
  generatedBy: "1.6.0"
---

Implement tasks from a Specbase change.

**Store selection:** If the user names a store (a store is a standalone Specbase repo registered on this machine) or the work lives in one, run `specbase store list --json` to discover registered store ids, then pass `--store <id>` on the commands that read or write specs and changes (`new change`, `status`, `instructions`, `list`, `show`, `validate`, `archive`, `doctor`, `context`). Other commands do not take the flag. Hints printed by commands already carry the flag; keep it on follow-ups. Without a store, commands act on the nearest local `specbase/` root.

**Input**: Optionally specify a change name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

1. **Select the change**

   If a name is provided, use it. Otherwise:
   - Infer from conversation context if the user mentioned a change
   - Auto-select if only one active change exists
   - If ambiguous, run `specbase list --json` to get available changes and use the **AskUserQuestion tool** to let the user select

   Always announce: "Using change: <name>" and how to override (e.g., `/spcb-apply <other>`).

2. **Check status to understand the schema**
   ```bash
   specbase status --change "<name>" --json
   ```
   Parse the JSON to understand:
   - `schemaName`: The workflow being used (e.g., "spec-driven")
   - `planningHome`, `changeRoot`, and `actionContext`: planning scope and edit constraints
   - Which artifact contains the tasks (typically "tasks" for spec-driven, check status for others)

3. **Get apply instructions**

   ```bash
   specbase instructions apply --change "<name>" --json
   ```

   This returns:
   - `contextFiles`: artifact ID -> array of concrete file paths (varies by schema - could be proposal/specs/design/tasks or spec/tests/implementation/docs)
   - Progress (total, complete, remaining)
   - Task list with status
   - Dynamic instruction based on current state

   **Handle states:**
   - If `state: "blocked"` (missing artifacts): show message, suggest using specbase-continue-change
   - If `state: "all_done"`: congratulate, suggest archive
   - Otherwise: proceed to implementation

4. **Read context files**

   Read every file path listed under `contextFiles` from the apply instructions output.
   The files depend on the schema being used:
   - **spec-driven**: proposal, specs, design, tasks
   - Other schemas: follow the contextFiles from CLI output

5. **Show current progress**

   Display:
   - Schema being used
   - Progress: "N/M tasks complete"
   - Remaining tasks overview
   - Dynamic instruction from CLI

6. **Implement tasks (loop until done or blocked)**

   For each pending task:
   - Show which task is being worked on
   - Make the code changes required
   - Keep changes minimal and focused
   - Mark task complete in the tasks file: `- [ ]` → `- [x]`
   - Continue to next task

   **Pause if:**
   - Task is unclear → ask for clarification
   - Implementation reveals a design issue → suggest updating artifacts
   - Error or blocker encountered → report and wait for guidance
   - User interrupts

7. **On completion or pause, show status**

   Display:
   - Tasks completed this session
   - Overall progress: "N/M tasks complete"
   - If all done: suggest archive
   - If paused: explain why and wait for guidance

**Output During Implementation**

```
## Implementing: <change-name> (schema: <schema-name>)

Working on task 3/7: <task description>
[...implementation happening...]
✓ Task complete

Working on task 4/7: <task description>
[...implementation happening...]
✓ Task complete
```

**Output On Completion**

```
## Implementation Complete

**Change:** <change-name>
**Schema:** <schema-name>
**Progress:** 7/7 tasks complete ✓

### Completed This Session
- [x] Task 1
- [x] Task 2
...

All tasks complete! Ready to archive this change.
```

**Output On Pause (Issue Encountered)**

```
## Implementation Paused

**Change:** <change-name>
**Schema:** <schema-name>
**Progress:** 4/7 tasks complete

### Issue Encountered
<description of the issue>

**Options:**
1. <option 1>
2. <option 2>
3. Other approach

What would you like to do?
```

**Guardrails**
- Keep going through tasks until done or blocked
- Always read context files before starting (from the apply instructions output)
- If task is ambiguous, pause and ask before implementing
- If implementation reveals issues, pause and suggest artifact updates
- Keep code changes minimal and scoped to each task
- Update task checkbox immediately after completing each task
- Pause on errors, blockers, or unclear requirements - don't guess
- Use contextFiles from CLI output, don't assume specific file names

**Fluid Workflow Integration**

This skill supports the "actions on a change" model:

- **Can be invoked anytime**: Before all artifacts are done (if tasks exist), after partial implementation, interleaved with other actions
- **Allows artifact updates**: If implementation reveals design issues, suggest updating artifacts - not phase-locked, work fluidly

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

### Delivering enforcement sources (governed)

Use `specbase coverage --json` as the aggregated coverage health signal while applying.

For every planned source: implement or update the source, link it with exactly `type`, requirement-level `covers`, and `source` in `enforcement.yaml`, execute it through its native project harness, and record the result. Do not copy commands, status, targets, procedures, or limitations into the compact manifest. Before cleaning up a retired file source, prove no surviving binding references it.
