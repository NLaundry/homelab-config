## Why

The current Behavior, Architecture, Ops, Code-quality, and Agents planes force homelab truths into software-oriented categories: runtime configuration appears as Behavior, repository layout appears as Architecture, and Ops mixes realization with temporal operation. Authors repeatedly have to debate placement, which is a clear taxonomy smell and makes enforcement easier to overclaim.

Nix and IaC make a sharper model possible: separate consumed outcomes, the desired estate graph, selected realization, time-based transitions, and the control system that governs all four.

## What Changes

- **BREAKING:** Replace the governed plane roster with exactly five homelab-native planes:
  - **Service** — steady-state outcomes observed by people, administrators, devices, and client services.
  - **Estate** — sites, hosts, roles, workload placement, dependencies, state/trust boundaries, authorities, and failure domains.
  - **Configuration** — proposal-worthy products, versions, Nix modules/options, addresses, listeners, mounts, identities, schedules, ACLs, and firewall realization.
  - **Lifecycle** — durable boot, deploy, update, rollback, revoke, backup, restore, failover, and recovery transitions.
  - **Governance** — the Nix/IaC repository, testing and evidence machinery, Specbase workflow, review instruments, and code/test quality.
- Adopt a deterministic classification order: split compound claims; then test Governance → Lifecycle → Service → Estate → Configuration. Give every fact one owner and reference it elsewhere without restatement.
- Decompose security by claim nature rather than adding a Security plane: outcomes are Service, trust/authority boundaries are Estate, settings are Configuration, transitions are Lifecycle, and repository controls are Governance.
- Reclassify all 15 current pairs and all 32 requirements through a requirement-level migration map. Preserve pair-local IDs where meaning survives; create new IDs only for split claims.
- Drop low-value permanent truth instead of copying it forward: incidental Vim/Git presence, implementation warning text, Make target/help existence, and unspecified update-cadence prose.
- Split existing compound NAS boot, access, Samba, deployment, and pin requirements so each surviving claim has one plane and one honest evidence boundary.
- Establish `governance/enforcement-quality` with objective conformance, representative mutation/fault sensitivity, and independent semantic review. A green helper-existence or wrapper-invocation check is not evidence.
- Preserve strong existing evidence—evaluated Nix assertions, isolated NixOS VM behavior, live macOS SMB probes, deployment diagnostics, tooling closure checks—and narrow or retire hollow bindings.
- Regenerate repo-specific Specbase skills and review-panel lens configuration from the new roster.
- Perform the roster replacement and current-tree migration as one atomic cutover staged and validated off-tree before replacing `specbase/config.yaml` and `specbase/specs/`.
- Defer the typed Estate registry to the next stack member. This change may leave Estate evidence review/manual-strength where physical or graph evidence does not yet exist; it will not invent a hollow checker.

## Planes

### Service

- `service.nas-capabilities`: SMB client capabilities and administrator access outcomes that survive equivalent product and placement changes (new, re-homed from Behavior).

### Estate

- `estate.nas-storage`: current NAS workload placement and durable storage ownership boundaries (new, extracted from compound NAS claims).

### Configuration

- `configuration.nas-realization`: selected ZFS, file-sharing, administrator-account, and host realization decisions worth governing (new, split from Behavior/Ops).

### Lifecycle

- `lifecycle.nas-transitions`: pool-import-on-boot and deployment transition guarantees (new, split from Behavior/Ops).

### Governance

- `governance.specbase`: Specbase workflow and review-panel instruments (new locator, re-homed from Agents).
- `governance.nix-repository`: flake entry, host-module ownership, and reproducible Nix pin policy (new locator, re-homed from Architecture/Ops).
- `governance.deployment-control`: repository deployment interface and input-selection rules (new locator, split from Ops).
- `governance.testing-control`: test-stage semantics, isolation, builder selection, and live-verification boundaries (new locator, re-homed from Architecture/Ops).
- `governance.operator-tooling`: reproducible operator tooling and catalogue (new locator, re-homed from Ops).
- `governance.enforcement-quality`: repository-wide evidence scope, independence, sensitivity, diagnostics, safety, freshness, limitations, and semantic review (new, absorbs Code-quality testing truth and extends it).

No parent pair is created merely to enumerate these leaves. The plane roots and intermediate directories are namespaces until shared invariants earn a pair.

## Enforcement intent

| Covered truth | Planned type | Planned source | Intended proof |
|---|---|---|---|
| NAS client capabilities | `test` | `tests/nas-vm.nix`, `tests/verify/nas-samba.bats` | Real SMB clients enumerate, mount, mutate, read, delete, deny, and clean up through the declared protocol. |
| NAS administrator access | `test` + `manual` until live automation is safe | evaluated account checks plus bounded SSH/`sudo -n` evidence | Separates declared account realization from an actual authorization outcome. |
| NAS placement and state ownership | `review` initially; later `static-analysis` | Estate lens, then the downstream typed Estate graph | Records the current topology honestly without pretending Nix option inspection proves physical placement. |
| NAS realization | `command` | evaluated Nix projections and closure builds | Asserts selected merged configuration rather than grepping source text. |
| Boot and deployment transitions | `test` + `manual` | deployment orchestration fixtures, live health observations, fenced boot/deploy evidence | Records before/event/after state and does not treat point-in-time health as proof of the transition. |
| Specbase instruments | `test` | `tests/agents/specbase-instruments.sh` and strict Specbase validation | The configured roster, generated workflow guidance, review lenses, and routing policy conform to the five-plane model. |
| Nix repository rules | `test`/`static-analysis` | evaluated flake outputs, closure checks, and source-layout checks only where layout is the subject | Proves repository contracts without using source shape as runtime evidence. |
| Testing control | `test` | existing private-network VM tests, builder checks, and runner fixtures | Registered test subjects remain isolated and stage semantics fail correctly. |
| Operator tooling | `test` + `review` | `tests/tooling/environment.bats` and operator-tooling review | Tool closures and shells are reproducible; catalogue semantics remain honestly reviewed. |
| Enforcement quality | `lint` + `test` + `review` | planned enforcement conformance, family-level fault fixtures, enforcement lens | Rejects structural hollowness, demonstrates representative sensitivity, and reviews semantic adequacy that automation cannot decide. |

## Impact

- `specbase/config.yaml`: authoritative plane replacement and new plane purposes/lenses.
- `specbase/specs/`: atomic migration from 15 old-plane pairs to the new pair tree, with a requirement-level mapping retained in this change.
- `.pi/skills/`, generated prompts, and review-panel configuration: regenerated from the new roster.
- Current enforcement files and test routing: rebound at assertion scope; low-information bindings retired or narrowed.
- No homelab runtime behavior, host placement, package selection, or deployed service is intentionally changed.
- Specbase stack sequencing keeps `introduce-typed-estate-registry` blocked until this change is applied and archived; its Estate/Governance artifacts are completed only after the new roster becomes current truth.
