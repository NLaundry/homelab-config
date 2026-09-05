## 1. Build the reusable NetBird OpenTofu root

- [ ] 1.1 Create `infra/netbird/` with pinned OpenTofu/provider requirements, committed provider locks for supported platforms, and a single North York site-module call.
- [ ] 1.2 Create `infra/netbird/modules/site-network/` for a site Network, resource definitions, and dedicated router group without a Network router or access policy resource.
- [ ] 1.3 Have the root derive the North York LAN CIDR from `estate.yaml`, pass it into the reusable module, and declare only that Network resource plus its empty router group; fail static validation on an absent, duplicate, or mismatched Estate boundary, and add no Scarborough placeholder or setup-key resource.
- [ ] 1.4 Configure the command adapter to use SOPS-delivered NetBird credentials, OpenTofu native state/plan encryption, external `TF_DATA_DIR`, and the external local-state path.
- [ ] 1.5 Add ignore and preflight controls that reject tracked state, state backups, plans, working data, and unsafe backend paths.

## 2. Deliver static IaC evidence

- [ ] 2.1 Implement `tests/iac/netbird-static-check` to run formatting, disposable-backend initialization, provider lock checks, `tofu validate`, and module tests with non-secret North York fixtures.
- [ ] 2.2 Implement `tests/iac/netbird-contracts.bats` to verify single-root ownership, Git state exclusion, North York-only scope, and absence of router, routed-policy, DNS, and setup-key resources.
- [ ] 2.3 Link `governance.network-iac` and `configuration.netbird` bindings to the static command and contract source, and add direct per-requirement entries for every new automated binding to `tests/specbase/enforcement-observations.json`.
- [ ] 2.4 Execute both sources through their native harnesses and record commands and results in change progress.

## 3. Adopt the live North York baseline

- [ ] 3.1 Write `docs/operations/netbird-opentofu.md` with live inventory, import, plan review, state backup, emergency drift reconciliation, and recovery procedures using sanitized examples.
- [ ] 3.2 Inventory the live NetBird account and confirm the exact North York object IDs, LAN CIDR, baseline resources, current router assignment, and effective routing state without adopting or changing Scarborough; stop on unexpected active routing or ambiguous object ownership.
- [ ] 3.3 Initialize the protected external state and import the existing North York Network and any matching resource/group into their final module addresses; create only objects proven absent.
- [ ] 3.4 Capture and manually review refresh-only and normal plans; explain every metadata-only normalization and stop on unexplained drift, replacement, router assignment, effective routed access, secret persistence, or an unrelated-site change.
- [ ] 3.5 Apply the accepted baseline, confirm the North York Network remains unrouted and pre-existing peer connectivity is unchanged, and record a sanitized state/object summary.

## 4. Prove state recovery and validate the prefix

- [ ] 4.1 Copy the encrypted post-apply state into the operator's external encrypted backup set and perform the documented isolated recovery drill.
- [ ] 4.2 Link `lifecycle.netbird-control` bindings to the import review and recovery-drill procedures, then record their manual results without state or credential contents.
- [ ] 4.3 Run a final no-change OpenTofu plan through the bounded secret adapter and record its summary.
- [ ] 4.4 Run normal repository and strict Specbase validation and record the results before OPNsense enrollment begins.
