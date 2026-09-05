## Context

The NAS (`NASty`, 10.10.10.11) is already deployed and shipped under a flake
(`flake.nix` → `nixosConfigurations.nas`), with host config split under
`hosts/nas/{default,zfs,hardware-configuration}.nix` and a `Makefile` for remote
deploy. Its durable truth was captured in a legacy flat OpenSpec spec
(`openspec-old/specs/nixos-deploy/spec.md`, `schema: spec-driven`) with a single
archived change (`flakify-nas`). The repo has since adopted the governed specbase
model (`schema: spec-driven-governed`, 5 paired planes: behavior, architecture,
ops, code-quality, agents), but only the two `agents` baseline pairs exist —
the NAS's behavior, architecture, and ops have no governed coverage and the
legacy spec carries no enforcement.

This change re-homes the already-shipped truth as governed plane-qualified pairs.
It is a **spec-only refactor**: the box, the flake, the modules, and the
Makefile are not touched. The historical `flakify-nas` archive (and its
deferred-decisions running list D1–D9) is re-homed verbatim so the transition
story survives in the dated archive rather than the permanent specs.

## Goals / Non-Goals

**Goals:**
- Express the NAS's durable truth as governed pairs — one spec per plane-qualified
  locator, never mixing planes within a spec.
- Pair every SHALL/MUST requirement with honest enforcement; prefer one
  high-leverage automated check per claim family, and use `manual` openly where
  the check genuinely requires the box.
- Keep NAS-scoped behavior nested under `behavior/storage/`; keep
  every-Nix-host architecture at the top level; keep run/deploy concerns in ops.
- Preserve the `flakify-nas` history at the canonical archive path; retire
  `openspec-old/`.

**Non-Goals:**
- Reconfiguring the deployed NAS — the box is unchanged; this re-specs existing
  truth.
- Re-writing the archived `flakify-nas` spec delta into governed form — it stays
  a historical snapshot of the pre-governed workflow.
- New `code-quality` or `agents` pairs — the legacy content asserts no smells/
  rules, and the repo's agentic instruments are already planted and untouched.
- Addressing the deferred decisions (D1–D9) — they stay deferred; this change
  only re-homes their container.

## Decisions

### D-A: Plane split of the legacy flat spec
The single legacy `nixos-deploy` spec mixed concerns. Governed truth splits by
plane, and a single capability touches several planes — so it becomes 7 pairs:
- **behavior** (NAS-scoped, nested under `behavior/storage/`): `nas-boot`,
  `nas-users`, `nas-utility-packages`.
- **architecture** (top-level, every Nix host): `flake-entry`, `host-modules`.
- **ops** (top-level): `deployment`, `nixpkgs-pin`.

The split is by the plane whose declared purpose fits each claim's nature, not
by the legacy requirement boundaries. E.g. the legacy "flake defines the NAS"
requirement split into `architecture/flake-entry` (entry point + host-agnostic
naming) and `ops/nixpkgs-pin` (input pin + eval-clean).

### D-B: NAS-scoped behavior nested under `behavior/storage/`
NAS-specific runtime outcomes (boot with pools imported; operator access;
utility packages) live under `behavior/storage/<pair>/`. The `storage/`
namespace groups the NAS's behavior subtree so a future second host gets its own
behavior subtree without touching these. Architecture pairs that must hold for
*every* Nix host stay at the top level (`architecture/flake-entry`,
`architecture/host-modules`), phrased generically — the NAS is the first
instance, not the only one.

### D-C: The Makefile lives in ops, not behavior
A repo-owned tool with user-visible outputs is, by the strict classifier,
behavioral truth. Here the better read is **ops**: the Makefile is the deploy
*interface*, and its targets are the run/deploy surface, which is ops-flavored.
So `ops/deployment` owns both the nixos-rebuild remote-deploy mechanism
(build on NAS via `--build-host`, activate via `--target-host` over SSH as
`operator` with passwordless sudo) and the Makefile target surface that exposes
it. If the target surface ever needs to be enforced as a public contract on its
own, that'd be the moment to split a `behavior/deploy-makefile` pair — not now.

### D-E: Enforcement mechanism per claim family
Per the philosophy (highest-leverage real check; bind at the requirement level;
honest review/manual where no automated check is meaningful):

| Claim family | Mechanism | Why |
|---|---|---|
| Declarative config intent (pools, hostId, kernel, forceImportRoot, operator, sudo, vim/git) | `command` — `nix eval` asserting the evaluated config values | One eval covers a whole family of "is this in the config" claims; high-leverage and reproducible from the workstation. |
| Structural invariants (flake exposes `.#<role>`; `hosts/<role>/default.nix` imports siblings) | `command` — conformance checks over the repo files | A grep/parse fitness function protects the invariant across the whole repo; architectural flavor. |
| Makefile target surface | `command` — `make -n <target>` expands to expected nixos-rebuild flags | Proves the target invokes the right command without running it. |
| Eval-cleanliness (forceImportRoot emits no warning; flake evaluates) | `command` — `nix flake check` / `nix eval` with warning capture | Proves the build property holds. |
| Runtime on the box (pools actually import on boot; operator can actually SSH + sudo; an end-to-end deploy succeeds) | `manual` — honest, requires the NAS | Genuinely unverifiable from the workstation; no hollow test to fake it. `manual` is first-class, not a demerit. |

No `review` bindings are proposed for these claims: each is either concretely
automatable from the workstation or concretely requires the box, so there is no
non-deterministic residue needing a lens here.

## Risks / Trade-offs

- **Spec drift from the box** -> The specs describe shipped truth; if the box
  later drifts (imperative edits on `NASty`), the specs go stale. Mitigation:
  the `command` bindings re-assert config intent from the *repo's* flake, which
  is what `make deploy` pushes — so drift shows up as a binding failure on the
  repo side. Runtime `manual` bindings catch on-box drift when exercised.
- **Re-homing the archive loses git history of the path** -> Moving
  `openspec-old/changes/archive/…` to `openspec/changes/archive/…` is a `git mv`;
  history follows the rename. The legacy `.openspec.yaml` (`schema: spec-driven`)
  is kept inside the moved archive as a historical marker, not re-validated.
- **Legacy `flakify-nas` spec delta is in the old flat format** -> Kept verbatim
  as a historical snapshot. It is not re-expressed as a governed delta; the
  governed pairs (this change) supersede its content going forward.
- **`behavior/storage/` namespace could be mistaken for a spec** -> It contains
  only child pairs (no `spec.md`), so under the governed rule it is a pure
  namespace and needs no pair of its own. Validate confirms this.
- **More files than the single legacy spec** -> 7 pairs (14 files) vs 1. The
  trade-off is plane-pure, enforceable truth; accepted.

## Migration Plan

1. Author the 7 governed spec deltas + paired enforcement (this change).
2. `git mv openspec-old/changes/archive/2026-08-06-flakify-nas
   openspec/changes/archive/2026-08-06-flakify-nas` (verbatim, with its legacy
   `.openspec.yaml` and flat `specs/nixos-deploy/spec.md` delta kept as a
   historical snapshot).
3. Delete `openspec-old/` (its durable content is now governed pairs; its
   archive is re-homed).
4. Fix the stale `README.md` reference from `openspec/changes/flakify-nas/design.md`
   to the archived path `openspec/changes/archive/2026-08-06-flakify-nas/design.md`.
5. `openspec validate --strict` to confirm the governed workflow is well-formed
   with the new pairs.
6. Archive this change so its deltas apply to `openspec/specs/`.

Rollback: the governed pairs and the re-homed archive are all git-tracked;
reverting the change's commits restores `openspec-old/` and removes the new
pairs. The deployed NAS is untouched at every step.

## Open Questions

- Should the `manual` on-box bindings (pools import on boot; operator SSH + sudo;
  end-to-end deploy) get a lightweight runbook under `docs/NAS/` so the manual
  procedure is repeatable rather than ad hoc? (Ties to the existing
  `docs/NAS/zpool-first-import.md` pattern; out of scope here but a natural
  follow-up.)
- When a second Nix host lands (deferred D4), do the top-level architecture pairs
  need a `hosts/` namespace, or do they stay general and each host gets its own
  `behavior/<host>/` subtree? (Decide then.)
