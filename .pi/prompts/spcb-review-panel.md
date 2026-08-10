---
description: "Run the governed review panel (read-only, review-strength, non-gating)"
---

Run the governed review panel over a change: a panel of narrow, blind, per-lens
reviewers judges the non-deterministic truth that no automated check proves. You
are the **orchestrator** — you pick lenses, run the deterministic gate first,
fan the reviewers out in parallel over the residue, dedup, refute-verify,
critique coverage, and report. You do **not** review the change yourself.

**The panel is READ-ONLY and NON-GATING.** Its findings are recorded as
`review`-strength evidence — weaker than automated proof by construction. A
panel finding NEVER blocks archive, flips verification readiness, or fails
`openspec coverage --strict`; those gate on structural rot only.

**Input**: optionally a change name after the command. If omitted, infer it from
**Provided arguments**: $@
context or prompt for selection with `openspec list --json`.

---

## Step 0 — Resolve scope from the governed model

Confirm the governed model and load the affected pairs:
```bash
openspec status --change "<name>" --json   # confirm specModel.kind == "governed"
openspec coverage --json                    # lens rollup, un-lensed gaps, split candidates
```
Read every affected `spec.md`/`enforcement.md` PAIR the status reports. The set
of **touched governed pairs** (their plane-qualified locators) is the router's
input. If the change touches no governed pair, say so and stop.

## Step 1 — Router: touched subtrees → lenses (scaled to the surface)

Map each touched pair to the **most-specific lens** whose spec-tree subtree
covers it, falling back up the tree to the plane-wide default — the same
resolution rule as `openspec show`/locator lookup. Scale the lens set to the
changed surface: a scoped lens fires only when its subtree is touched, and a
trivial diff spawns nobody.

**Lens scope = a spec-tree subtree.** The four default lenses:

| Lens | Question | Default scope |
|---|---|---|
| `architectural` | Does the code deviate from the architecture specs' invariants and boundaries? | `architecture/**` |
| `behavioural` | Does the code produce the behavioral specs, consistently and unerringly? | `behavior/**` |
| `enforcement` | Do the bound checks actually exercise the claim, not merely run? | every pair's bindings |
| `code-quality` | Is the code clean, simple, and free of cruft? | whole tree |

A pair under a scoped lens (e.g. `architecture/rings/boundaries`) routes to that
scoped lens **rather than** the plane-wide `architectural` one (most-specific
wins). A pair with a `review`/`manual` binding that declares `lens: <id>` routes
to that named lens.

**Then explicitly `log`** the selected lens set and, for EVERY lens **skipped**,
why (e.g. "`architectural` skipped — no `architecture/` pair touched"). Silence
is never coverage: the skipped list is part of the report and the completeness
critic (step 5) audits it.

**Flag un-lensed claims.** A `review`/`manual` binding whose `lens` resolves to
no defined lens (or whose claim no lens covers) is an **un-lensed review** gap —
report it and suggest pointing it at an existing lens or proposing a new/scoped
one. Never invent a lens on the fly.

## Step 2 — Deterministic gate FIRST, then compute the residue

Run the project's declared automated bindings (their `run: {command, args, cwd}`
vectors) BEFORE any reviewer, so each lens reviews only the residue above the
gate. For each lens, prepare two inputs:
1. **already-covered findings** — the concrete gate output, so no reviewer
   re-reports a line a deterministic check already flagged.
2. **blind list** — the deterministic binding IDs named in each review binding's
   `covered_by`. As deterministic bindings are added to `covered_by`, the
   reviewed residue shrinks with NO edit to any lens method.

If the gate is red, note it prominently at the top of the report — the panel
reviews the gap above a passing gate, it does not excuse a failing one.

## Step 3 — Fan-out: parallel, blind, one slice each

Spawn each selected lens as an independent reviewer **in parallel** (they are
blind to each other; that independence is the design). Hand each reviewer, at run
time, the policy **sliced fresh from the governed specs its scope covers** — the
specs are the living docs; never copy charter/rule text into a lens method. Each
reviewer receives: its method, the sliced spec policy, the change, the
already-covered findings, and its `covered_by` blind list. It returns findings as
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
triggers it, or explain why it cannot fire. Only findings that survive refutation
stay at high severity; a refuted one is downgraded or dropped, with a note.
Medium/low are reported as-is.

**Completeness critic.** Run one final reviewer asking: given the touched pairs,
which lens **should have run and did not**? Cross-check the router's skipped-lens
log against the actual change surface. A lens that never ran is not a clean bill.

## Step 6 — Report: read-only, severity-grouped, lens-attributed

Emit ONE report: the lenses run and skipped (with why), the deterministic gate
status, then findings grouped **High / Medium / Low**, each tagged by lens(es)
and marked verified/downgraded, plus a Coverage section (completeness-critic gaps
and un-lensed review claims). Record every finding as **`review`-strength**.

State explicitly that the panel is read-only: **it changes no code, and its
verdicts do not gate archive, verification readiness, or `--strict`.**

---

## Default lens methods (method only — policy comes from the specs at review time)

Each lens judges EXACTLY ONE concern and is blind to the others. It reads its
policy fresh from the governed specs its scope covers; it holds no copied rules.

### `architectural` — scope `architecture/**`
Read the affected `specs/architecture/...` pairs' invariants and boundary rules.
Judge only whether the change DEVIATES from them (a forbidden dependency edge, a
broken boundary, a violated cross-cutting invariant). Behavior, tests, and style
belong to other lenses — drop them.

### `behavioural` — scope `behavior/**`
Read the affected `specs/behavior/...` pairs. Judge only whether the code
**produces** those observable capabilities, consistently and unerringly (missing
cases, wrong outputs, broken contracts). Structure and cleanliness are not yours.

### `enforcement` — scope: every affected pair's bindings (the keystone)
Judge whether each binding's declared check actually **exercises** the covered
claim rather than merely running (a test that imports but asserts nothing, a lint
that never fires). Audit **automated** bindings too, not just review ones — but
judge evidence adequacy only, and **do not review your own verdicts** (no
recursion into the enforcement lens itself).

### `code-quality` — scope: whole tree
Judge cleanliness, simplicity, and cruft — dead code, needless complexity,
duplication. Not correctness (that is `behavioural`), not structure (that is
`architectural`).

---

## Growth by proposal, never automatic

When a non-deterministic claim has no home, POINT it at an existing lens or
PROPOSE a new/scoped lens through the normal change workflow — a lens is added
(or a broad lens split into a scoped one) as a change, never created or split
automatically. `openspec coverage` surfaces the pressure (un-lensed gaps, split
candidates); the human makes the call. This mirrors hardening (review →
automated): the tool shows the case, the person decides.
