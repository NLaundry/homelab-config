---
name: openspec-archive-change
description: Archive a completed change in the experimental workflow. Use when the user wants to finalize and archive a change after implementation is complete.
allowed-tools: Bash(openspec:*)
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.6.0"
---

Archive a completed change in the experimental workflow.

**Store selection:** If the user names a store (a store is a standalone OpenSpec repo registered on this machine) or the work lives in one, run `openspec store list --json` to discover registered store ids, then pass `--store <id>` on the commands that read or write specs and changes (`new change`, `status`, `instructions`, `list`, `show`, `validate`, `archive`, `doctor`, `context`). Other commands do not take the flag. Hints printed by commands already carry the flag; keep it on follow-ups. Without a store, commands act on the nearest local `openspec/` root.

**Input**: Optionally specify a change name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

1. **If no change name provided, prompt for selection**

   Run `openspec list --json` to get available changes. Use the **AskUserQuestion tool** to let the user select.

   Show only active changes (not already archived).
   Include the schema used for each change if available.

   **IMPORTANT**: Do NOT guess or auto-select a change. Always let the user choose.

2. **Check artifact completion status**

   Run `openspec status --change "<name>" --json` to check artifact completion.

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
   - Compare each delta spec with its corresponding main spec at `openspec/specs/<capability>/spec.md`
   - Determine what changes would be applied (adds, modifications, removals, renames)
   - Show a combined summary before prompting

   **Prompt options:**
   - If changes needed: "Sync now (recommended)", "Archive without syncing"
   - If already synced: "Archive now", "Sync anyway", "Cancel"

   If user chooses sync, use Task tool (subagent_type: "general-purpose", prompt: "Use Skill tool to invoke openspec-sync-specs for change '<name>'. Delta spec analysis: <include the analyzed delta spec summary>"). Proceed to archive regardless of choice.

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
- Use artifact graph (openspec status --json) for completion checking
- Don't block archive on warnings - just inform and confirm
- Preserve .openspec.yaml when moving to archive (it moves with the directory)
- Show clear summary of what happened
- If sync is requested, use openspec-sync-specs approach (agent-driven)
- If delta specs exist, always run the sync assessment and show the combined summary before prompting

## Governed spec model

This project uses the governed spec model (2 permanent truth planes with paired enforcement). Do NOT assume the flat `specs/<capability>/spec.md` layout.

**Confirm the model from the CLI, do not guess:**
- Run `openspec status --change "<name>" --json` and read `specModel`.
- The governed model reports `specModel.kind == "governed"` with
  `planes: [behavior, architecture]` and `pairedEnforcement: true`.
- If `specModel.kind` is `legacy` (or absent), follow the flat-spec guidance
  above unchanged.

**Under the governed model, derive concrete paths from CLI output** (`status`
`artifactPaths` and `openspec instructions <artifact> --change ... --json`),
never hardcode them. Durable truth lives in the declared planes:
- behavior: User/client-visible outcomes (enforcement: tests / property tests) → `specs/behavior/<locator>/{spec.md,enforcement.md}`
- architecture: Package responsibilities, boundaries, and structural invariants (enforcement: lint / static-analysis / conformance) → `specs/architecture/<locator>/{spec.md,enforcement.md}`

Every governed `spec.md` is PAIRED with an `enforcement.md`. Stable identity is
scoped narrowly: the frontmatter `id` (e.g. `behavior.<locator>`) is the only project-unique governed ID; requirement, scenario, and binding `**ID:**` slugs are unique only within their pair, and stay fixed when titles or locators move.

**Plane classification:** match each proposed claim to the plane whose declared
purpose best fits the claim's nature. The shipped defaults are behavior, architecture; a single initiative may touch several planes — list one spec per plane touched, never mix planes in one spec.

**Structure conventions (governed):**
- Locators may nest to arbitrary safe depth (e.g. `behavior/platforms/desktop`);
  JSON reports normalized slash-separated locators, filesystem access is native.
- A directory that only GROUPS child pairs is a **namespace** and needs no pair of
  its own. Only a directory that contains `spec.md` must also contain
  `enforcement.md`; ancestry provides navigation, never inherited requirements.
- A change stores its `spec.md` and `enforcement.md` deltas under the SAME
  plane-qualified locator as the target current pair, so both members move together.

### Archiving a governed change (governed)

Governed archive promotes a change into durable truth only when its complete
spec/enforcement PAIRS are verified, reconciled together, and free of unresolved
enforcement. The legacy artifact/task/delta prompts above still apply; the
governed gate below is ADDITIONAL and authoritative.

- **Require governed readiness BEFORE archiving.** Do not archive until the
  affected `spec.md`/`enforcement.md` PAIRS validate together (`openspec
  validate` / `openspec spec validate`), coverage is satisfied (no **hanging**
  mandatory SHALL/MUST claims, no **stale** or uncovered bindings), every active
  binding's declared `targets` exist, and NO `planned`, unenforced, unresolved,
  **broken**, or failing-mandatory bindings remain. Reuse the `/spcb-verify`
  results as the readiness evidence; if verification has not been run or does not
  pass, block ordinary archive readiness and direct the user to `/spcb-verify`
  or the explicit validation-bypass command. Interactive confirmation is NOT
  enforcement evidence - never treat a "proceed anyway" answer as proof the pair
  is enforced.
- **Treat governed deltas as an inseparable pair on sync.** When a governed change
  has complete paired deltas, show ONE combined summary of the normative, binding,
  and retired-target operations that archive will apply, then invoke **pair-aware
  governed synchronization** (the governed archive CLI path) so `spec.md` and
  `enforcement.md` reconcile together by stable identity. Never promote a
  spec-only or enforcement-only half. If only ONE member of a governed delta pair
  exists, report a blocking validation error rather than offering partial
  synchronization.
- **Archive through the schema-aware CLI path.** Run the archive via the governed
  archive command so pair validation, current-state pair updates, archive-root
  selection, and bypass reporting stay authoritative - do not hand-move governed
  pair files. On success, report the dated archive location, the updated current
  locators, the resulting enforcement status, and any cleanup candidates.
- **Report retired-target CLEANUP candidates; never auto-delete project code.**
  When reconciliation retires a binding or a normative ID it covered, surface the
  binding's former `targets` (tests, rules, fixtures, review procedures) as
  **cleanup candidates**. Before any manual removal, assess whether a surviving
  binding still references each candidate; never delete a shared or intentionally
  retained target, and never auto-delete project code from this workflow.
- **Report an explicit BYPASS honestly.** If the user deliberately chooses the
  supported validation bypass, invoke the CLI with its required confirmation flags
  (e.g. `--no-validate`) and report the result as **unverified (validation
  bypassed)** - state that the archive was NOT fully verified rather than claiming
  governed readiness.
