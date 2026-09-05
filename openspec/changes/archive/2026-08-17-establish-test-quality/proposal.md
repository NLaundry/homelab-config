## Why

The testing harness determines where checks run, but weak evidence can still pass while exercising copied logic, partial outcomes, timing assumptions, shared residue, or unsafe cleanup. The repository needs a small prospective quality contract and an advisory review route that actually applies that contract whenever test sources change.

## What Changes

- Add atomic test-quality rules for production-path fidelity, defect-sensitive assertions, bounded synchronization, run-scoped state, order independence, cleanup execution and failure preservation, residual failure and identity, and outcome/context diagnostics.
- Apply the rules to repository tests and the helpers they invoke, including Nix assertions, NixOS VM tests, Bats tests, and shell helpers under the repository test tree.
- Route changes under `tests/**` through the `code-quality.testing` policy even when the change does not otherwise touch a Code-quality pair.
- Keep all review findings advisory and accept honest review-strength/degraded coverage rather than creating semantic meta-tests that cannot prove the rules.
- Keep runner selection, live-verification identities, mutable-state boundaries, and capability-specific assertions outside this change.

## Planes

### Code quality

- `code-quality.testing`: universal qualities and prohibited smells for repository tests and their helpers (new).

### Agents

- `agents.review-panel`: path-aware routing that supplies the testing policy to advisory review when repository test sources change (modified).

## Spec pairs

- `code-quality.testing` -> paired advisory review through the enforcement and code-quality lenses.
- `agents.review-panel` -> paired instrument-conformance source proving that test-source changes select the testing policy.

## Enforcement intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| production-path fidelity and defect-sensitive assertions | `review` | `enforcement` | Review traces each covered requirement to an independent assertion over the responsible production path. |
| synchronization, state isolation, cleanup, residue, and diagnostics | `review` | `code-quality` | Review rejects timing assumptions, shared state, unsafe cleanup, hidden residue, and failures without useful context. |
| test-source review routing | `command` | `tests/agents/specbase-instruments.sh#test-quality-routing` | A controlled changed-path fixture proves that `tests/**` selects the Code-quality testing policy without making review gating. |

## Impact

- Updates the repo-owned review-panel skill and its instrument conformance source.
- Replaces the obsolete Markdown enforcement member in this change with compact `enforcement.yaml` pairs.
- Depends on `establish-testing-operations` for the initial test tree and operation boundaries.
- Becomes a prerequisite for capability-specific verification changes; live mutation safety is established separately by `establish-live-verification-safety`.
