# Requirement Migration Map

This manifest accounts for every current governed requirement before the plane-roster replacement. “Preserve” means the pair-local ID survives in the destination pair. New IDs are introduced only for atoms split from a compound source requirement.

| # | Current requirement | Verdict | Post-migration destination | Evidence disposition |
|---:|---|---|---|---|
| 1 | `agents.review-panel#panel-covers-planes` | Keep and update roster | `governance.specbase#panel-covers-planes` | Retain roster/lens conformance; update expected planes and scopes. |
| 2 | `agents.review-panel#panel-routes-test-quality` | Keep and update policy | `governance.specbase#panel-routes-test-quality` | Retain add/modify/rename/delete routing fixtures; target `governance.enforcement-quality`. |
| 3 | `agents.spec-driven#practices-sdd` | Keep | `governance.specbase#practices-sdd` | Retain config inspection and strict validation; assert exact five-plane roster. |
| 4 | `architecture.flake-entry#flake-exposes-role-attribute` | Keep | `governance.nix-repository#flake-exposes-role-attribute` | Retain evaluated output check; narrow source-text checks to layout only. |
| 5 | `architecture.host-modules#host-module-split` | Keep | `governance.nix-repository#host-module-split` | Retain structural conformance; do not claim runtime behavior. |
| 6 | `architecture.testing-isolation#test-subject-boundary` | Keep | `governance.testing-control#test-subject-boundary` | Existing VMs support the claim; universal coverage needs registered-target conformance. |
| 7 | `architecture.testing-isolation#test-network-boundary` | Keep | `governance.testing-control#test-network-boundary` | Retain private-network VM assertions; add registry-wide scope when available. |
| 8 | `behavior.storage.nas-boot#pools-import-on-boot` | Split | `lifecycle.nas-transitions#pools-import-on-boot`; `configuration.nas-realization#zfs-pool-import-configuration`; `estate.nas-storage#zfs-pool-placement` | Eval proves selected state only; boot/ONLINE remains fenced live evidence; Estate remains review/reconciliation until registry lands. |
| 9 | `behavior.storage.nas-boot#force-import-root-clean` | Split/drop | `configuration.nas-realization#force-import-root-disabled`; warning-text atom dropped | Retain evaluated false value; delete warning-string contract. |
| 10 | `behavior.storage.nas-samba#samba-shares-exposed` | Split | `service.nas-capabilities#samba-shares-exposed`; `estate.nas-storage#smb-workload-placement` | Retain VM/live SMB protocol evidence for Service; placement needs Estate evidence. |
| 11 | `behavior.storage.nas-samba#guest-force-operator` | Keep | `service.nas-capabilities#guest-force-operator` | Retain VM/live write/read/delete and cleanup observations. |
| 12 | `behavior.storage.nas-users#operator-access` | Split | `service.nas-capabilities#operator-access`; `configuration.nas-realization#operator-account-configuration` | Eval proves account policy; live authorization requires bounded probe or retained manual evidence. |
| 13 | `behavior.storage.nas-utility-packages#utility-packages-enabled` | Demote/drop | Ordinary Nix configuration; no governed requirement | Existing eval is accurate but protects an incidental choice. |
| 14 | `code-quality.testing#production-path-fidelity` | Keep | `governance.enforcement-quality#production-path-fidelity` | Retain semantic review; add deterministic/mutation support where real. |
| 15 | `code-quality.testing#run-scoped-state` | Keep | `governance.enforcement-quality#run-scoped-state` | Retain review; use live-probe fixture/mutation evidence as concrete support. |
| 16 | `code-quality.testing#failure-safe-live-cleanup` | Keep | `governance.enforcement-quality#failure-safe-live-cleanup` | Retain review; require injected cleanup-failure or residue fixture per reusable family. |
| 17 | `code-quality.testing#actionable-test-failures` | Keep | `governance.enforcement-quality#actionable-test-failures` | Retain review; deterministic evidence checks structured diagnostics where present. |
| 18 | `ops.deployment#remote-deploy-mechanism` | Split | `governance.deployment-control#remote-deploy-mechanism`; `lifecycle.nas-transitions#deployment-succeeds` | Controlled adapters prove plan/orchestration only; real success remains live/manual. |
| 19 | `ops.deployment#deployment-operation-set` | Keep | `lifecycle.nas-transitions#deployment-operation-set` | Retain operation semantics fixtures with explicit boundary. |
| 20 | `ops.deployment#post-activation-verification` | Keep | `lifecycle.nas-transitions#post-activation-verification` | Retain controlled ordering and failure fixtures. |
| 21 | `ops.deployment#post-activation-failure-semantics` | Keep | `lifecycle.nas-transitions#post-activation-failure-semantics` | Retain exit/report behavior fixtures. |
| 22 | `ops.deployment#deployment-inputs-overridable` | Keep | `governance.deployment-control#deployment-inputs-overridable` | Retain alternate-value and mutant fixtures. |
| 23 | `ops.deployment#post-deploy-verification` | Keep | `lifecycle.nas-transitions#post-deploy-verification` | Retain independent live health observations; do not claim they prove the transition. |
| 24 | `ops.nixpkgs-pin#nixpkgs-release-pinned` | Split/drop | `governance.nix-repository#nixpkgs-release-pinned`; vague cadence atom dropped | Replace source grep with lock/eval/stateVersion cross-check and closure evidence. |
| 25 | `ops.repository-operations#makefile-operation-surface` | Drop | No governed requirement | Target/help existence is low-information UX shape, not durable homelab truth. |
| 26 | `ops.testing#lint-stage` | Keep | `governance.testing-control#lint-stage` | Preserve ordering/failure intent; strengthen beyond fake invocation logs when practical. |
| 27 | `ops.testing#test-stage` | Keep | `governance.testing-control#test-stage` | Preserve non-live boundary; do not bind wrapper success as evidence for child phases. |
| 28 | `ops.testing#test-builder-selection` | Keep | `governance.testing-control#test-builder-selection` | Retain fixed aggregate/store identity and real KVM attestation. |
| 29 | `ops.testing#verify-stage` | Keep | `governance.testing-control#verify-stage` | Retain selection/non-activation/failure propagation; subject-plane probes prove outcomes. |
| 30 | `ops.tooling#repository-tool-set` | Keep | `governance.operator-tooling#repository-tool-set` | Retain cross-system evaluated inventories/builds and adapter mutants. |
| 31 | `ops.tooling#operator-dev-shell` | Keep | `governance.operator-tooling#operator-dev-shell` | Retain Darwin/Linux shell evaluation and derivation dependency checks. |
| 32 | `ops.tooling#tooling-catalogue` | Keep | `governance.operator-tooling#tooling-catalogue` | Keep independent Governance review for role/scope/authority semantics. |

## New Governance requirements

The migration adds four repository-wide requirements in `governance.enforcement-quality`:

- `assertion-scoped-evidence` — a binding claims no more than its direct observations.
- `evidence-record-integrity` — live/manual/drill evidence records provenance, freshness, environment, limitations, blast radius, and cleanup without secrets.
- `evidence-family-fault-detection` — each reusable evidence family demonstrates detection of a representative defect after introduction or major rewrite.
- `enforcement-quality-review` — semantic adequacy receives independent enforcement-lens review and is never inferred from helper existence or wrapper success.

## Pair retirement accounting

All 15 old-plane spec IDs retire at the atomic roster cutover. Their dated history remains in Git and this change archive. The post-migration pairs are new project identities because authority moves across plane boundaries; pair-local requirement/scenario IDs remain stable where this manifest says Keep.
