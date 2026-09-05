# Review panel record

## Deterministic gate

Passed independently of review findings:

- strict current and change validation,
- 41/41 requirement coverage with no broken, stale, hanging, incomplete, orphaned, or unlensed claims,
- locked flake evaluation and NAS closure realization,
- routine harness, cross-system tooling, forced KVM VM leaves, and bounded live verification,
- assertion-scope/target/evidence-record conformance and controlled mutation fixtures,
- ShellCheck, shfmt, and staged-diff whitespace checks.

The five degraded pairs are intentional review/manual boundaries: Estate physical ownership, enforcement semantic adequacy, tooling catalogue semantics, deferred boot/deployment transitions, and point-in-time operator authorization.

## Lenses

All projected lenses ran because the migration touches every plane and test changes invoke enforcement-quality policy:

- Service: clean.
- Estate: clean.
- Configuration: clean.
- Lifecycle: one verified high finding, resolved and re-reviewed clean.
- Governance: two verified high findings across the initial and follow-up pass, resolved.
- Enforcement: one verified high plus five medium/low findings, all resolved or honestly narrowed.
- Completeness critic: clean; no skipped or missing lens and no unlensed review binding.

## Review-strength findings and resolutions

1. **Lifecycle — deployment target drift (high, verified):** activation overrides did not reach verification. `Makefile` now passes the resolved target, address, and SSH identity to the verify runner; controlled execution proves the same values arrive.
2. **Governance — test-only early stop (high, verified):** generated review guidance stopped before path routing. Step 0 now preserves staged path records and stops only when neither pair nor test route selects a lens.
3. **Enforcement — incomplete assertion-scope gate (high, verified):** a selection-only source claimed subject disposability and single bindings escaped declarations. The weak binding was removed; every automated binding now declares exact requirement observations. Semantic adequacy remains Enforcement review-strength rather than automated proof.
4. **Governance — wrong test-quality lens (high, verified):** test changes initially selected the general Governance lens. The route now selects the cross-cutting Enforcement lens with `governance/enforcement-quality` as policy.
5. **Enforcement — live cleanup sensitivity (medium):** added trapped post-acquisition failure, TERM, cleanup-failure/residue, and exact cleanup fixtures.
6. **Enforcement — namespace collision risk (medium):** live SMB namespaces now contain 128 random bits; 128 controlled allocations must be unique.
7. **Enforcement — editable revision labels (medium):** current evidence records now reference deterministic implementation content, a digest-emitting execution log, and a digest-checked final attestation with log hashes.
8. **Enforcement — partial host concern ownership (medium):** conformance now checks ZFS, Samba, Avahi, and hardware ownership and rejects a duplication mutant.
9. **Enforcement — generic record diagnostics (low):** schema failures now include record identity, expected typed fields, and observed metadata.
10. **Enforcement — self-fulfilling semantic proof (medium):** automated bindings no longer claim `assertion-scoped-evidence`; the conformance output supports the independent Enforcement review that owns semantic correspondence.
11. **Enforcement — stale manual evidence pointers (low):** manual procedures now reference the digest-bound metadata, final logs, and execution attestation rather than earlier exploratory logs.

The final focused routing review was clean. The final Enforcement re-review found only the two stale-pointer items in item 11; both were corrected and verified against the staged paths.

Panel findings are review-strength and did not replace or override deterministic gates.
