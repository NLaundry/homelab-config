# Homelab-native governed spec planes

## Goal

Test whether a Nix/IaC homelab can be governed almost entirely through spec-driven development. Specbase defines durable intent and acceptance criteria; Nix realizes the desired estate; evaluation, builds, VM tests, live probes, and recovery drills provide evidence.

The homelab can be almost entirely spec-governed even though Nix alone cannot prove physical disks, cabling, live routing, external services, or successful restoration.

## Proposed planes

### Service

Own steady-state outcomes directly observed by people, administrators, devices, and client services. Examples include reachable endpoints, protocol behavior, authorization outcomes, and usable capabilities. Service truth survives equivalent technology and workload-placement changes.

### Estate

Own the desired graph of the homelab: sites, physical and logical roles, workload placement, dependencies, trust and state boundaries, identity authorities, network relationships, and failure domains. Estate changes when a node, edge, responsibility, placement, or boundary changes.

### Configuration

Own deliberate realization choices whose change deserves a proposal: products, packages, versions, NixOS modules and options, internal listeners, addresses, mounts, datasets, users and groups, ACL/firewall realization, schedules, and other selected values. It is curated policy, not a prose copy of all Nix.

An equivalent technology substitution that preserves Service and Estate truth changes Configuration only. Example: CoreDNS to PowerDNS with the same DNS contract, role, topology, and dependencies.

### Lifecycle

Own recurring or durable time/transition guarantees: provision, boot, deploy, update, rollback, rotate, revoke, backup, restore, failover, decommission, and incident recovery. One-time migration steps remain in the change design or a temporary runbook.

### Governance

Own the IaC control system: Nix repository conventions, flake and registry shape, CI/builders, test isolation and safety, Specbase workflow, review panels, agent instruments, and code/test quality.

## Classification decision tree

1. Split compound sentences before classification.
2. If the subject is the repository or its control machinery, use Governance.
3. If removing time/event/transition language destroys the claim, use Lifecycle.
4. If the claim is a steady-state outcome observed by a client, device, or administrator, use Service.
5. If it changes a node, role, placement, dependency, authority, boundary, or failure domain in the desired graph, use Estate.
6. If it selects a product, value, address, listener, mount, account, ACL, firewall rule, or declarative mechanism, use Configuration.
7. Give each fact one owner. Other planes reference it rather than restating it.

Security is decomposed rather than made a plane: authorization outcomes are Service; trust/identity boundaries are Estate; products/groups/ACLs/cert settings are Configuration; enrollment/rotation/revocation are Lifecycle; repository secret controls are Governance.

## Pressure-test conclusions

- Adding Navidrome naturally touched Service, Estate, and Configuration; no Lifecycle or Governance delta was needed until a durable backup/update/recovery policy was chosen.
- Adding a Compute host and moving existing services changed Estate only when consumed capabilities and selected realization policies stayed unchanged.
- Consolidating NAS and Compute responsibilities on one host changed Estate placement and the physical failure boundary, not Service.
- Adding a second site over a mesh legitimately touched Service reachability, Estate topology/trust boundaries, Configuration product/routes/ACLs, and possibly Lifecycle offboarding and gateway recovery.
- Replacing CoreDNS with PowerDNS while preserving outcomes and topology changed Configuration only.
- Nix files changing does not automatically imply a Configuration spec delta. Spec deltas follow changed durable truth, not changed implementation files.

## Boundary rules needing care

- Client-visible endpoint or port: Service. Internal listener and firewall realization: Configuration.
- Workload-to-role or host placement: Estate. Product/module/settings used to realize the placement: Configuration.
- Identity authority and trust realms: Estate. Allowed/denied action: Service. Group names and ACL syntax: Configuration. Revocation transition: Lifecycle.
- Post-reboot or recovery time-bound claims: Lifecycle, not duplicated in Service.
- Replica location and independent failure domain: Estate. Snapshot schedule, retention, product, and encryption: Configuration. Recovery objective and restore capability: Lifecycle.

## Enforcement pressure-test results

The enforcement model is viable when each evidence layer stays honest about what it proves:

```text
static/eval -> closure build -> isolated VM -> live estate -> recovery drill
```

Declared-model conformance is not deployed truth. A buildable closure is not a booted system. VM behavior is not proof of physical disks, Apple clients, the real LAN, external mesh control planes, or two-site availability. A live probe is a point-in-time observation, not proof of recovery. A backup job or snapshot is not evidence that restoration works.

### Service evidence

Use protocol-native clients acting from outside the service node. Prefer reusable multi-node VM suites with authorized and unauthorized personas, then bounded live probes from representative real networks and clients. Examples include SMB discovery/mount/read/write/delete, DNS authoritative/forwarded/negative answers over UDP and TCP, Git clone/push/denial, OIDC authorization and token validation, and role-to-service reachability matrices.

A package, listener, firewall declaration, active unit, or open TCP socket cannot prove a Service claim. Negative access tests require a positive reachability control so an outage cannot masquerade as a correct denial.

### Estate evidence

Evaluate a typed Estate graph containing sites, hosts, roles, workloads, dependencies, state ownership, authorities, routes, trust boundaries, and failure domains. Apply independent properties such as unique workload placement, no dangling dependencies, explicit durable-state ownership, forbidden-edge absence, unique identity authority, and replica separation across declared failure domains. Emit a normalized graph diff for every proposed topology change.

Graph validation proves the declared model only. Reconcile selected facts against independently observed host identities, active workload placement, routes, mounts, or provider inventory. Physical site, power, cabling, cooling, and ISP independence remain live/manual observations or review.

### Configuration evidence

Use evaluated NixOS configuration, module assertions, cross-host properties, lock and derivation identity, closure builds, generated-configuration parsing, and isolated VM startup. Bind only proposal-worthy selected state; do not mirror every Nix attribute in prose. Source grep is rejected whenever evaluated state is available.

A successful service probe does not prove that the intended closure or configuration is active. Query the deployed generation and mutable external providers independently to detect drift.

### Lifecycle evidence

Exercise transitions rather than checking that transition machinery exists. Reusable families should cover reboot, activation, rollback, dependency loss, credential revocation, gateway replacement, backup and restore, and fenced failure injection. Record state before, the applied event, state after, elapsed time, cleanup, and rollback target.

Recovery evidence should seed independent fixtures, destroy an isolated primary, restore from the backup or replica, compare externally held checksums and semantic state, and measure observed recovery point and recovery time. Synthetic destructive tests require allowlisted disposable targets and must fail closed if a production pool or device is visible. Representative real restores remain supervised drills with explicit fencing.

### Governance evidence

Automate objective conformance: Specbase validation, evaluated flake-output shape, Nix static checks, secret scanning, dependency/import rules, test isolation, target resolution, binding scope, provenance, and evidence freshness. Preserve honest review for whether a test exercises its claim, follows the production path, remains maintainable, and is worth its cost. Do not create a meta-test that merely checks that the anti-hollow review script exists.

### Evidence reuse

One execution may emit distinct observations for several planes, but bindings remain assertion-specific. For example, one DNS VM can show that generated configuration starts (Configuration), client answers match the contract (Service), and answers return after an injected restart (Lifecycle). Shared setup and a broad test-file exit code are not evidence.

Expected policy and observed state must not come from the same unvalidated source. Live state must be queried independently of the deployment command. VM and live probes should use different clients where practical. Every evidence record should identify the commit, lock, closure/generation, environment, source persona, time, and probe version without recording secrets.

### Anti-hollow acceptance rubric

Accept a binding only when:

1. It observes the requirement's subject rather than the existence or invocation of a helper.
2. Expected and observed values are meaningfully independent.
3. A realistic mutant or injected fault has made the reusable test family fail for the intended reason.
4. It distinguishes denial or expected failure from unreachability, skipped execution, and harness failure.
5. Its environment, limitations, provenance, freshness, secret handling, blast radius, and cleanup are explicit.
6. Its claimed coverage is no broader than its actual observations.
7. The failure output tells the operator what differed, where, and against which generation or environment.

Reject source-text checks when evaluation is available, wrapper-success bindings, scripts that only assert other scripts exist or were invoked, broad commands bound to unrelated requirements, and automation created only to replace honest review/manual evidence.

### Evidence budget

For each capability, start with at most:

1. One independent static/property family.
2. One representative runtime happy path.
3. One highest-risk negative or transition case.

Additional bespoke automation must cover a distinct defect class with material risk and named maintenance cost. Requirements should share a small evidence platform rather than each creating a shell wrapper.

### Minimum high-value stack

1. A typed Nix Estate registry that emits machine-readable graph data.
2. Independent graph/property checks and diagnostic graph diffs.
3. Evaluated host policy and closure builds for touched systems.
4. A reusable multi-node NixOS VM library with private networks, personas, virtual disks, and fault injection.
5. Protocol-native probes reusable in VM and live environments.
6. Independent post-deploy generation/drift observation with structured evidence.
7. Isolated ZFS backup/restore tests plus periodic fenced real restore drills.
8. Objective Governance lint plus explicit anti-hollow enforcement review.

### Current repository evidence

The existing Samba VM test, private-network VM harness, live macOS SMB round trip, evaluated Nix/JQ checks, and deployment-health diagnostics are strong foundations. Weak patterns include duplicate bindings, source grep for an evaluated value, Make target/help existence checks, dry-run command-shape checks overclaimed as deployment evidence, and fake invocation-log tests that prove phases were named rather than that they produced meaningful observations.

The largest improvement will come from narrower claims and assertion-specific bindings, not a larger test count.

## Testing ownership clarification

Lifecycle is not a testing plane. It owns homelab promises whose meaning depends on time or a transition, such as reboot, deployment, rollback, revocation, backup, restore, and recovery. The test or drill for such a claim remains paired with its Lifecycle requirement.

Governance owns the durable rules for evidence quality and the shared machinery that declares, executes, records, and reviews evidence across every plane. A candidate `governance/enforcement-quality` pair would govern assertion-level scope, independent expected values, proof that reusable evidence families detect representative injected defects, diagnostic structured results, live-test safety, freshness, and honest limitations.

Enforcement quality has three trust anchors rather than an infinite chain of meta-tests:

1. Deterministic conformance for objective structure, provenance, freshness, target resolution, and safety metadata.
2. Mutation or fault fixtures showing that each reusable evidence family fails for the intended reason.
3. Independent enforcement-quality review for semantic adequacy that automation cannot honestly decide.

The actual claim stays in its subject plane: Service uses protocol evidence, Estate uses graph and reconciliation evidence, Configuration uses evaluation/build evidence, and Lifecycle uses transition/drill evidence. Governance constrains the quality of those mechanisms without taking ownership of their domain truths.

## Deterministic test derivation from Nix

Static source walking is not a sound basis for meaningful derivation. Nix modules are functions; imports and definitions can be conditional or computed; overlays, priorities, `mkIf`, `mkDefault`, `mkForce`, laziness, and module merging determine the final result. The reliable boundary is evaluated NixOS configuration and deliberately exported structured data.

Nix can deterministically derive Configuration assertions, closure builds, generated-configuration validation, host and workload subjects, VM topology, test execution plans, and evidence targets. A typed homelab registry could expose sites, hosts, roles, workload placement, dependencies, endpoints, state ownership, identities, routes, trust and failure domains, plus references to requirement IDs.

Nix cannot independently derive intended service outcomes, authorization policy, expected DNS answers, recovery objectives, real-client compatibility, or physical independence. Deriving both expected and observed values from the same evaluated registry creates a tautology. The preferred model is:

```text
Specbase requirement / independent policy fixture -> expected outcome
Evaluated Nix registry                         -> test subject and topology
Reusable protocol or transition adapter       -> executable plan
Live or VM observation                         -> evidence
```

Therefore derive test subjects and plans aggressively, but keep expectations independent. Requirement IDs may travel into generated test names, derivation metadata, and structured evidence without parsing requirement prose or making prose generate code.

A minimal experiment would export a small typed Estate/Service registry, combine it with independent policy fixtures, generate graph properties and all-host closure checks, generate one multi-node Samba test and one live probe plan, and mutation-test the generator with wrong placement, missing shares, unreachable services, and false-denial cases.
