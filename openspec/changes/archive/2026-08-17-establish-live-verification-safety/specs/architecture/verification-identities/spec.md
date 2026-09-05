---
id: architecture.verification-identities
---

## Purpose

Remote live verification has its own limited authority and mutable-state boundary so accepted test operations remain distinguishable from human administration and cannot reach ordinary homelab state.

## ADDED Requirements

### Requirement: Testing authority is a distinct principal
**ID:** `testing-principal-distinct`
The live-verification topology SHALL represent testing authority with a principal distinct from human operator and deployment principals.

#### Scenario: A verification session is attributed
**ID:** `verification-session-distinct`
- **WHEN** the verification endpoint accepts a client session
- **THEN** the accepted principal is neither a human operator nor a deployment principal

### Requirement: Remote testing authority is least-privileged
**ID:** `testing-authority-limited`
Remote homelab boundaries SHALL deny the testing principal administrative, deployment, interactive-login, and ordinary-data authority.

#### Scenario: The testing credential is misused
**ID:** `tester-cannot-administer`
- **WHEN** the testing credential is presented to an administrative or ordinary-data boundary
- **THEN** that boundary denies the operation

### Requirement: Accepted live mutation is confined to verification state
**ID:** `mutation-state-boundary`
Every mutation accepted through the dedicated verification endpoint SHALL target state beneath a verification root that contains no ordinary homelab data.

#### Scenario: A mutation targets an ordinary share
**ID:** `ordinary-state-mutation-rejected`
- **WHEN** the testing principal attempts to mutate an ordinary-data boundary
- **THEN** that boundary denies the operation

### Requirement: Verification state has bounded capacity
**ID:** `verification-capacity-boundary`
The verification state boundary SHALL enforce finite storage capacity independently of storage required by ordinary homelab data.

#### Scenario: A tester exhausts its allowance
**ID:** `fixture-capacity-exhausted`
- **WHEN** verification state reaches its configured byte or inode limit
- **THEN** further tester allocation fails without consuming ordinary-data capacity

### Requirement: Run state remains identifiable and collision-free
**ID:** `run-state-separation`
Every fixture resource created by a repository live-verification client SHALL belong to exactly one collision-resistant run namespace, and creation SHALL reject a namespace that already exists.

#### Scenario: Two verification runs choose one namespace
**ID:** `duplicate-run-rejected`
- **WHEN** a run attempts to create a namespace already present beneath the verification root
- **THEN** creation fails without modifying the existing namespace
