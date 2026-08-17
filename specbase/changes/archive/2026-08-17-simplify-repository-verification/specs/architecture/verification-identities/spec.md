---
id: architecture.verification-identities
---

## Purpose

This retired pair previously defined the trust and mutable-state boundaries of a dedicated live-verification principal.

## REMOVED Requirements

### Requirement: Testing authority is a distinct principal
**ID:** `testing-principal-distinct`
**Reason:** The hidden authenticated verification capability is retired.
**Migration:** Live behavior uses the same guest boundary as ordinary SMB clients.

### Requirement: Remote testing authority is least-privileged
**ID:** `testing-authority-limited`
**Reason:** No dedicated remote testing principal remains.
**Migration:** Remove the tester account and its boundary-specific checks.

### Requirement: Accepted live mutation is confined to verification state
**ID:** `mutation-state-boundary`
**Reason:** Dedicated fixture state is retired in favor of direct ordinary-share behavior.
**Migration:** Live transactions use one unique verifier-prefixed namespace and exact cleanup on each selected ordinary share.

### Requirement: Verification state has bounded capacity
**ID:** `verification-capacity-boundary`
**Reason:** The independent test-only tmpfs is removed.
**Migration:** No replacement capacity partition is required for one small bounded guest transaction.

### Requirement: Run state remains identifiable and collision-free
**ID:** `run-state-separation`
**Reason:** The cross-run fixture service is retired.
**Migration:** Each live guest transaction creates one collision-resistant namespace and never shares mutable setup with another run.
