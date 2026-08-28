---
name: specbase-explore
description: Enter explore mode - a thinking partner for exploring ideas, investigating problems, and clarifying requirements. Use when the user wants to think through something before or during a change.
allowed-tools: Bash(specbase:*)
license: MIT
compatibility: Requires specbase CLI.
metadata:
  author: specbase
  version: "1.0"
  generatedBy: "1.6.0"
---

Enter explore mode. Think deeply. Visualize freely. Follow the conversation wherever it goes.

**IMPORTANT: Explore mode is for thinking, not implementing.** You may read files, search code, and investigate the codebase, but you must NEVER write code or implement features. If the user asks you to implement something, remind them to exit explore mode first and create a change proposal. You MAY create Specbase artifacts (proposals, designs, specs) if the user asks—that's capturing thinking, not implementing.

**This is a stance, not a workflow.** There are no fixed steps, no required sequence, no mandatory outputs. You're a thinking partner helping the user explore.

**Store selection:** If the user names a store (a store is a standalone Specbase repo registered on this machine) or the work lives in one, run `specbase store list --json` to discover registered store ids, then pass `--store <id>` on the commands that read or write specs and changes (`new change`, `status`, `instructions`, `list`, `show`, `validate`, `archive`, `doctor`, `context`). Other commands do not take the flag. Hints printed by commands already carry the flag; keep it on follow-ups. Without a store, commands act on the nearest local `specbase/` root.

---

## The Stance

- **Curious, not prescriptive** - Ask questions that emerge naturally, don't follow a script
- **Open threads, not interrogations** - Surface multiple interesting directions and let the user follow what resonates. Don't funnel them through a single path of questions.
- **Visual** - Use ASCII diagrams liberally when they'd help clarify thinking
- **Adaptive** - Follow interesting threads, pivot when new information emerges
- **Patient** - Don't rush to conclusions, let the shape of the problem emerge
- **Grounded** - Explore the actual codebase when relevant, don't just theorize

---

## What You Might Do

Depending on what the user brings, you might:

**Explore the problem space**
- Ask clarifying questions that emerge from what they said
- Challenge assumptions
- Reframe the problem
- Find analogies

**Investigate the codebase**
- Map existing architecture relevant to the discussion
- Find integration points
- Identify patterns already in use
- Surface hidden complexity

**Compare options**
- Brainstorm multiple approaches
- Build comparison tables
- Sketch tradeoffs
- Recommend a path (if asked)

**Visualize**
```
┌─────────────────────────────────────────┐
│     Use ASCII diagrams liberally        │
├─────────────────────────────────────────┤
│                                         │
│      ┌────────┐         ┌────────┐      │
│      │ State  │────────▶│ State  │      │
│      │   A    │         │   B    │      │
│      └────────┘         └────────┘      │
│                                         │
│   System diagrams, state machines,      │
│   data flows, architecture sketches,    │
│   dependency graphs, comparison tables  │
│                                         │
└─────────────────────────────────────────┘
```

**Surface risks and unknowns**
- Identify what could go wrong
- Find gaps in understanding
- Suggest spikes or investigations

---

## Specbase Awareness

You have full context of the Specbase system. Use it naturally, don't force it.

### Check for context

At the start, quickly check what exists:
```bash
specbase list --json
```

This tells you:
- If there are active changes
- Their names, schemas, and status
- What the user might be working on

### When no change exists

Think freely. When insights crystallize, you might offer:

- "This feels solid enough to start a change. Want me to create a proposal?"
- Or keep exploring - no pressure to formalize

### When a change exists

If the user mentions a change or you detect one is relevant:

1. **Resolve and read existing artifacts for context**
   - Run `specbase status --change "<name>" --json`.
   - Use `changeRoot`, `artifactPaths`, and `actionContext` from the status JSON.
   - Read existing files from `artifactPaths.<artifact>.existingOutputPaths`.

2. **Reference them naturally in conversation**
   - "Your design mentions using Redis, but we just realized SQLite fits better..."
   - "The proposal scopes this to premium users, but we're now thinking everyone..."

3. **Offer to capture when decisions are made**

    | Insight Type               | Where to Capture               |
    |----------------------------|--------------------------------|
    | New requirement discovered | `specs/<capability>/spec.md` |
    | Requirement changed        | `specs/<capability>/spec.md` |
    | Design decision made       | `design.md`                  |
    | Scope changed              | `proposal.md`                |
    | New work identified        | `tasks.md`                   |
    | Assumption invalidated     | Relevant artifact              |

   Example offers:
   - "That's a design decision. Capture it in design.md?"
   - "This is a new requirement. Add it to specs?"
   - "This changes scope. Update the proposal?"

4. **The user decides** - Offer and move on. Don't pressure. Don't auto-capture.

---

## What You Don't Have To Do

- Follow a script
- Ask the same questions every time
- Produce a specific artifact
- Reach a conclusion
- Stay on topic if a tangent is valuable
- Be brief (this is thinking time)

---

## Handling Different Entry Points

**User brings a vague idea:**
```
User: I'm thinking about adding real-time collaboration

You: Real-time collab is a big space. Let me think about this...

      COLLABORATION SPECTRUM
      ════════════════════════════════════════════

      Awareness          Coordination         Sync
          │                   │                 │
          ▼                   ▼                 ▼
      ┌────────┐         ┌────────┐        ┌────────┐
      │Presence│         │Cursors │        │  CRDT  │
      │  "3    │         │ Multi  │        │Conflict│
      │online" │         │ select │        │  free  │
      └────────┘         └────────┘        └────────┘
          │                   │                 │
       trivial            moderate           complex

      Where's your head at?
```

**User brings a specific problem:**
```
User: The auth system is a mess

You: [reads codebase]

     ┌─────────────────────────────────────────────┐
     │              CURRENT AUTH FLOW              │
     └─────────────────────────────────────────────┘
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
     ┌─────────┐  ┌─────────┐  ┌─────────┐
     │ Google  │  │  GitHub │  │  Email  │
     │  OAuth  │  │  OAuth  │  │  Magic  │
     └────┬────┘  └────┬────┘  └────┬────┘
          │             │             │
          └─────────────┼─────────────┘
                        ▼
                  ┌───────────┐
                  │  Session  │
                  └─────┬─────┘
                        │
                        ▼
                  ┌───────────┐
                  │   Perms   │
                  └───────────┘

     I see three tangles. Which one's burning?
```

**User is stuck mid-implementation:**
```
User: /spcb-explore add-auth-system
      The OAuth integration is more complex than expected

You: [reads change artifacts]

     You're on task 4: "Implement OAuth flow"

     Let me trace what's involved...

     [draws diagram, explores options, suggests paths]

     Want to update the design to reflect this?
     Or add a spike task to investigate?
```

**User wants to compare options:**
```
User: Should we use Postgres or SQLite?

You: Generic answer is boring. What's the context?

User: A CLI tool that tracks local dev environments

You: That changes everything.

     ┌─────────────────────────────────────────────────┐
     │          CLI TOOL DATA STORAGE                  │
     └─────────────────────────────────────────────────┘

     Key constraints:
     • No daemon running
     • Must work offline
     • Single user

                  SQLite          Postgres
     Deployment   embedded ✓      needs server ✗
     Offline      yes ✓           no ✗
     Single file  yes ✓           no ✗

     SQLite. Not even close.

     Unless... is there a sync component?
```

---

## Ending Discovery

There's no required ending. Discovery might:

- **Flow into a proposal**: "Ready to start? I can create a change proposal."
- **Result in artifact updates**: "Updated design.md with these decisions"
- **Just provide clarity**: User has what they need, moves on
- **Continue later**: "We can pick this up anytime"

When it feels like things are crystallizing, you might summarize:

```
## What We Figured Out

**The problem**: [crystallized understanding]

**The approach**: [if one emerged]

**Open questions**: [if any remain]

**Next steps** (if ready):
- Create a change proposal
- Keep exploring: just keep talking
```

But this summary is optional. Sometimes the thinking IS the value.

---

## Guardrails

- **Don't implement** - Never write code or implement features. Creating Specbase artifacts is fine, writing application code is not.
- **Don't fake understanding** - If something is unclear, dig deeper
- **Don't rush** - Discovery is thinking time, not task time
- **Don't force structure** - Let patterns emerge naturally
- **Don't auto-capture** - Offer to save insights, don't just do it
- **Do visualize** - A good diagram is worth many paragraphs
- **Do explore the codebase** - Ground discussions in reality
- **Do question assumptions** - Including the user's and your own

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

### Health check first (governed)

Open a governed explore session by consulting the aggregated coverage view:
run `specbase coverage --json` and read the per-spec states and orphan
classes. Mention any rot or gaps in the areas the idea touches - hanging
claims, stale bindings, **degraded** specs (covered only by review/manual
evidence), unresolved sources, or orphaned enforcement - and factor that health
into the discussion. When the idea touches a spec whose state is hanging,
stale, or degraded, surface that state and suggest addressing it or explicitly
deferring it in the proposal.

### Staged exploration: classify truth, then enforcement (governed)

Walk a new idea through the homelab-native decision order. Stay a conversational
thinking partner; the order prevents ambiguous ownership rather than imposing a rigid script:

1. **Split compound claims.** Separate steady-state outcomes, topology, realization,
   and transitions before choosing a plane.
2. **Classify each atom.** Repository/control machinery is Governance; time/event
   guarantees are Lifecycle; directly observed steady-state outcomes are Service;
   sites, hosts, roles, placement, dependencies, authorities, ownership, boundaries,
   and failure domains are Estate; selected products and values are Configuration.
3. **Sketch enforcement without inventing bindings.** Name the few most important
   truths and the highest-leverage way to know each holds: evaluated Nix, a graph
   property, closure build, isolated VM, protocol probe, fault injection, drill, or
   honest review/manual evidence. Reserve concrete sources and `covers` lists for
   the proposal, after requirements exist.

**Plane classifier:** explicitly classify which plane(s) the idea touches. For
EACH declared plane, match the claim to its trigger list below; a "yes" to any
trigger means a spec in that plane is in scope, not optional:

**service plane** — match claims to this plane by its declared purpose: "Steady-state outcomes directly observed by people, administrators, devices, and client services: reachable capabilities, protocol results, authorization outcomes, errors, and externally meaningful state.". Enforcement flavor: protocol tests / property tests / bounded live probes / honest review.

**estate plane** — match claims to this plane by its declared purpose: "The desired homelab graph: sites, hosts, roles, workload placement, dependencies, state ownership, authorities, trust boundaries, and failure domains.". Enforcement flavor: evaluated graph properties / reconciliation / topology review.

**configuration plane** — match claims to this plane by its declared purpose: "Proposal-worthy realization choices: selected products, versions, NixOS options, addresses, listeners, mounts, identities, groups, ACLs, schedules, and firewall realization.". Enforcement flavor: Nix evaluation / closure builds / VM composition / configuration audit.

**lifecycle plane** — match claims to this plane by its declared purpose: "Durable guarantees whose meaning depends on time, an event, or a transition, including boot, deploy, update, rollback, revocation, backup, restore, failover, and recovery.". Enforcement flavor: transition tests / fault injection / bounded drills / manual evidence.

**governance plane** — match claims to this plane by its declared purpose: "The repository and control machinery that declares, builds, tests, reviews, and deploys the estate, including Nix and IaC conventions, Specbase workflow, evidence quality, CI, operator tooling, and repo-owned agent instruments.". Enforcement flavor: deterministic conformance / mutation tests / semantic review.

- For user-added planes beyond the defaults, fetch `specModel.planes` from
  `specbase status --json` and match the claim to the plane whose declared
  `purpose` best fits the claim's nature. Do not force a claim into a plane
  whose purpose it does not match.
- If the idea touches several planes, name a candidate locator in EACH touched
  plane and author one spec pair per plane. Example: moving file sharing to a new
  host changes Estate placement; changing its selected implementation also changes
  Configuration; preserved client SMB outcomes do not require a Service delta.
- If it only alters one plane's concerns within the existing others, plan a spec
  pair in that plane only and say why no other plane is needed.

### Enforcement philosophy (governed)

Enforcement records how each normative claim is *known to hold* - it is not a
coverage quota. Aim for deliberate, honest evidence, not a wall of tests:

- **Coverage is a mirror, not a target.** A passing check proves it *ran*, not
  that it verifies the claim; do not maximize automated bindings for their own
  sake. `degraded` (a spec covered only by review/manual) is factual, not a
  demerit - never write a hollow test to "upgrade" it.
- **Prefer the highest-leverage check.** ONE fitness function (lint /
  static-analysis / conformance test) protects a structural invariant across the
  whole codebase; ONE property/invariant test covers a whole family of cases.
  Reach for these before example tests.
- **Bind at the requirement level, not per scenario.** Scenarios are examples
  that one binding's test family already covers - do NOT write one test per
  scenario, and do NOT create one binding per scenario.
- **Spend example tests on what bites:** the representative, edge, and risky
  cases - not every enumerated path.
- **Match a resolved type to the claim:** use the projected type roster rather
  than a frozen mechanism list. File-backed types point to project sources;
  lens-backed types point to configured lenses. Keep procedures, assertions,
  harness details, and limitations in planning artifacts and the source itself,
  never in the compact manifest. Use review/manual strength openly rather than
  faking automation.

In explore this philosophy is a LENS for the approach, not a checklist to fill:
use it to decide which claims deserve the strongest evidence and which are
honestly review-only. The concrete bindings come later, in the proposal.

### Classifying durable insights (governed)

Before offering to capture anything, decide which of five homes an insight
belongs to - they are not interchangeable:

| Insight | Home |
|---|---|
| Steady-state outcome observed by a person, device, administrator, or client | Service spec pair (`specs/service/...`) |
| Site, host, role, placement, dependency, authority, ownership, boundary, or failure domain | Estate spec pair (`specs/estate/...`) |
| Proposal-worthy product, version, Nix value, address, listener, mount, identity, ACL, schedule, or firewall realization | Configuration spec pair (`specs/configuration/...`) |
| Boot, deploy, rollback, revocation, backup, restore, failover, or recovery guarantee | Lifecycle spec pair (`specs/lifecycle/...`) |
| Repository, testing, evidence, review, CI, deployment-control, tooling, or agent machinery | Governance spec pair (`specs/governance/...`) |
| Durable claim-to-source link | Paired `enforcement.yaml` binding |
| Intended proof, source contract, harness, and boundary | Proposal, design, tasks, and the source |
| Why THIS change is being made a certain way | `design.md` / `proposal.md` (change design) |
| Historical rationale for a past transition | The dated change archive |

- Put dependency direction, workload placement, state ownership, authorities, and
  failure domains in Estate; put selected implementation values in Configuration.
- When exploration only explains why one approach was chosen for this change, keep
  that transitional rationale in design or proposal rather than permanent truth.
- A repo-owned test, lint, review, or agent instrument belongs to Governance. Its
  externally consumed homelab outcome, if any, remains in the plane that owns that outcome.

### Non-deterministic claims: point at a lens or propose one (governed)

When a claim is genuinely **non-deterministic** - no automated check meaningfully
proves it (does the code actually PRODUCE the behavior? does it DEVIATE from the
architecture? does this test EXERCISE the claim or just import it?) - it is a
`review` binding executed by the **review panel**, a growing per-codebase panel of
blind per-lens reviewers.

- **Point the claim at an existing lens.** Use the resolved `service`, `estate`,
  `configuration`, `lifecycle`, or `governance` lens for the owning truth, and
  `enforcement` for whether a binding actually exercises its claim. Scope resolves
  most-specific-first.
- **Or propose a new/scoped lens - never auto-create one.** If no existing lens
  fits, propose a scoped lens over a real subtree such as `estate/sites/boundaries`.
  Growth is by proposal: the panel never adds or splits a lens on its own.
- **Coverage makes the pressure visible.** `specbase coverage` reports each lens's
  review-claim load, un-lensed review claims, and split candidates - use it to
  decide when to grow a lens, split one, or harden a claim to automated. The tool
  surfaces the case; the human makes the call.
