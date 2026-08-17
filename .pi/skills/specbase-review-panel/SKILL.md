---
name: specbase-review-panel
description: Run the review panel — router, deterministic gate, blind per-lens reviewers over the residue, refute-verify, completeness critic, read-only severity/lens report. The lens set projects the resolved review model; findings are review-strength and never gate.
allowed-tools: Bash(specbase:*)
license: MIT
compatibility: Requires specbase CLI.
metadata:
  author: specbase
  version: "1.0"
  generatedBy: "1.6.0"
---

**Store selection:** If the user names a store (a store is a standalone Specbase repo registered on this machine) or the work lives in one, run `specbase store list --json` to discover registered store ids, then pass `--store <id>` on the commands that read or write specs and changes (`new change`, `status`, `instructions`, `list`, `show`, `validate`, `archive`, `doctor`, `context`). Other commands do not take the flag. Hints printed by commands already carry the flag; keep it on follow-ups. Without a store, commands act on the nearest local `specbase/` root.

Run the specbase review panel over a change: a panel of narrow, blind, per-lens
reviewers judges the non-deterministic truth that no automated proof proves. You
are the **orchestrator** — you pick the lenses this project's review model
projects, run the deterministic gate first (when bindings exist), fan the
reviewers out in parallel over the residue, dedup, refute-verify, critique
incompleteness, and report. You do **not** review the change yourself.

**The panel is READ-ONLY and NON-GATING.** Its findings are recorded as
`review`-strength evidence — weaker than automated proof by construction. A
panel finding NEVER blocks archive, flips verification readiness, or fails
`specbase coverage --strict`; those continue to gate on structural rot only.

**Input**: optionally a change name after the command. If omitted, infer it from
context or prompt for selection with `specbase list --json`.

---

## Step 0 — Resolve the review model

Confirm the review model and load the affected pairs:
```bash
specbase status --change "<name>" --json   # resolve the model and touched pairs
specbase coverage --json                    # lens rollup, un-lensed gaps, split candidates
```
Read every affected `spec.md` / `enforcement.yaml` pair the status reports. The
set of touched pairs and the complete changed-path name/status records are the
router's inputs. Preserve both paths for renames and copies. If the change
touches no spec pair and no repository test path, say so and stop.

## Step 1 — Router: touched subtrees → the projected lenses

Map each touched pair to the **most-specific** lens whose scope covers it,
falling back up the tree to the plane-wide default — the same resolution rule as
`specbase show`/locator lookup. Scale the lens set to the changed surface: a
lens fires only when its subtree is touched, and a trivial diff spawns nobody.

**Lens scope = the projected lens set for this project:**

| Lens | Question | Scope |
|---|---|---|
| `behavioural` | Does the code produce the behavioral specs, consistently and unerringly? | `behavior/**` |
| `architectural` | Does the code deviate from the architecture specs' invariants and boundaries? | `architecture/**` |
| `ops` | Does the repo use what the ops specs declare and run it as declared? | `ops/**` |
| `code-quality` | Is the code clean, simple, and free of cruft? | `code-quality/**` |
| `enforcement` | Do the bound checks actually exercise the claim, not merely run? | every pair's bindings |

A pair under a scoped lens (e.g. `architecture/rings/boundaries`) routes to that
scoped lens rather than the plane-wide one (most-specific wins). A lens the model
does not project simply does not exist here.

<!-- test-quality-route-contract:start -->
Before finalizing the lens set, require the selected change to be fully staged
and require unrelated workspace changes to remain unstaged; if the index mixes
changes, stop and request a clean selected-change index. Run
`.pi/skills/specbase-review-panel/route-test-quality.sh` with no arguments. It
uses `git diff --cached --name-status --diff-filter=ACDMRTUXB` as the canonical,
read-only changed-path producer, including both paths for renames and copies. If
it emits `code-quality\tcode-quality/testing`, select the `code-quality` lens
and load the current `code-quality/testing` pair as policy even when no
Code-quality delta is touched. This path route is additive to ordinary pair
routing. Added, modified, deleted, or either side of renamed/copied paths beneath
`tests/**` select the policy; non-test paths do not. The selected lens remains
advisory and non-gating like every other panel lens.
<!-- test-quality-route-contract:end -->

Then explicitly **`log`** the selected lens set and, for EVERY lens **skipped**,
why (e.g. "`architectural` skipped — no `architecture/` pair touched").
Silence is never coverage: the skipped list is part of the report and the
completeness critic (step 5) audits it. **Every finding is tagged with its lens.**

## Step 2 — Deterministic gate FIRST (when bindings exist), then compute the residue

Run the project's declared automated binding sources through their native
project harness BEFORE any reviewer, so each lens reviews only the residue above
the gate. For each lens, prepare two inputs:
1. **already-covered findings** — the concrete gate output, so no reviewer
   re-reports a line a deterministic check already flagged.
2. **blind list** — the deterministic binding IDs named in each review binding's
   `covered_by`. As deterministic bindings are added to `covered_by`, the
   residue shrinks with NO edit to any lens method.

If the gate is red, note it prominently at the top of the report — the panel
reviews the residue above a passing gate, it does not excuse a failing one.

## Step 3 — Fan-out: parallel, blind, one slice each

Spawn each selected lens as an independent reviewer **in parallel** (they are
blind to each other; that independence is the design). Hand each reviewer, at run
time, the spec + evidence **sliced fresh from the specs AND their enforcement bindings** — the specs are
the living policy; never copy charter/rule text into a lens method, and do not
copy a fix literally from the diff. Each reviewer returns findings as
`path:line — defect [high|medium|low]`, a why-sentence citing the slice, and a
fix, or states plainly that its lens is clean. Keep each reviewer inside its lens.

## Step 4 — Dedup / synthesize by file:line

Merge every reviewer's findings keyed by `file:line`: same line + same defect →
one entry tagged with **both** lenses; same line + different defects → keep both.
Preserve each finding's lens attribution and severity. Discard anything already
in the already-covered set that slipped through.

## Step 5 — Refute-verify (high severity) + completeness critic

**Refute by default.** For **every high-severity** finding, run an independent
second opinion whose job is to **refute** it: construct the concrete input that
truthfully triggers it, or explain why it cannot fire. Only findings that survive
refute stay at high severity; a refuted one is downgraded or dropped, with a
note. Medium/low are reported as-is.

**Completeness critic.** Run one final reviewer asking: given the touched pairs,
which lens **should have run and did not**? Cross-check the skipped-lens log
against the actual change surface. A lens that never ran is not a clean bill.

## Step 6 — Report: read-only, severity-grouped, lens-attributed

Emit ONE report: the lenses run and skipped (with why), the deterministic gate
status (or a "no gate — flat project" note), then findings grouped
**High / Medium / Low**, each tagged by lens(es) and marked verified/downgraded,
plus a Coverage section (completeness-critic gaps and un-lensed review claims).
Record every finding as **`review`-strength**.

State explicitly that the panel is read-only: **it changes no code, and its
verdicts do not gate archive, verification readiness, or `--strict`.**

---

## Lens methods (method only — the policy comes from the spec at review)

Each lens judges EXACTLY ONE concern and is blind to the others. It reads its
policy fresh from the specs it covers; it holds no copied rules.

### `behavioural` — scope: `behavior/**`
Read the affected `specs/behavior/...` pairs and the code they describe.
Judge only whether the implementation honors Does the code produce the behavioral specs, consistently and unerringly? Nothing outside its
plane (structure, style, correctness elsewhere) is yours — drop it.

### `architectural` — scope: `architecture/**`
Read the affected `specs/architecture/...` pairs and the code they describe.
Judge only whether the implementation honors Does the code deviate from the architecture specs' invariants and boundaries? Nothing outside its
plane (structure, style, correctness elsewhere) is yours — drop it.

### `ops` — scope: `ops/**`
Read the affected `specs/ops/...` pairs and the code they describe.
Judge only whether the implementation honors Does the repo use what the ops specs declare and run it as declared? Nothing outside its
plane (structure, style, correctness elsewhere) is yours — drop it.

### `code-quality` — scope: `code-quality/**`
Read the affected `specs/code-quality/...` pairs and the code they describe.
Judge only whether the implementation honors Is the code clean, simple, and free of cruft? Nothing outside its
plane (structure, style, correctness elsewhere) is yours — drop it.

### `enforcement` — scope: every affected pair's bindings
Judge whether each binding's declared check actually **exercises** the covered
claim rather than merely running (a test that imports but asserts nothing, a lint
that never fires). Audit **automated** bindings too, not just review ones — but
judge evidence adequacy only, and **do not review your own verdicts** (no
recursion into the enforcement lens itself).

---

## Growth by proposal, never automatic

When a non-deterministic claim has no home, POINT it at an existing lens or
PROPOSE a new/scoped lens through the normal change workflow — a lens is added
(or a broad lens split into a scoped one) as a change, never created or split
automatically. `specbase coverage` surfaces the pressure (un-lensed gaps, split
candidates); the human makes the call. This mirrors hardening (review →
automated): the tool shows the case, the person decides.

---

**Panel scope (read-only).** The panel cannot be asked to change code; it can
only apply these lens review runs in parallel and report. It never makes a
code edit, never touches archive readiness, and its verdicts do not enter the
diff.
