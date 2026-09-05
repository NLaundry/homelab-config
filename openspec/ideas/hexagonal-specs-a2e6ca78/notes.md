# Hexagonal specs

## Core model

Treat the governed planes as orthogonal kinds of truth rather than literal concentric layers:

- **Behavior** records what users and clients can observe and rely on.
- **Architecture** records enduring roles, ports, dependencies, trust boundaries, state boundaries, and placement constraints.
- **Ops** records the concrete adapters selected to fill those roles: products, runtimes, packages, tooling, hardware, and operating mechanisms.

A capability forms a vertical, hexagonal-style spec set across the planes. For a movie service:

- Behavior: authorized users can browse and stream movies at a stable public URL.
- Architecture: a media-application role reads the library, owns metadata state, depends on identity, and is reached through ingress.
- Ops: Jellyfin fills the media role; a microVM provides the workload boundary; QEMU/KVM runs the VM; a selected physical host supplies compute.

## Exposed adapters

An adapter is not automatically unobservable. If users depend on Jellyfin-native clients, APIs, authentication, or plugins, Jellyfin-specific compatibility is also behavioral truth. If Plex could replace Jellyfin without user-visible change, the product choice remains Ops-only.

Classify a replacement by asking:

1. Does it change what a user or client observes? If yes, Behavior changes.
2. Does it change roles, dependencies, trust, state, or failure boundaries? If yes, Architecture changes.
3. Does it only change the selected realization? If yes, Ops changes.

A replacement may legitimately touch more than one plane. The model should reveal that coupling rather than hide it.

## Split compound claims

Statements such as \"the NAS serves Jellyfin at this port\" contain several facts:

- public reachability and public URLs or ports -> Behavior;
- service role and dependency boundaries -> Architecture;
- Jellyfin, internal listener ports, microVM/LXC, QEMU/KVM, and the current device -> Ops;
- a public vendor-specific protocol -> Behavior and an Ops selection.

## Ops selection catalogue

The Ops plane should act as the catalogue of selected adapters. Selections should be role-centric so stable IDs survive replacement. Candidate categories include:

- repository tooling: Nix, Make, Bats, NixOS test driver;
- deployment adapters: nixos-rebuild and SSH;
- workload runtimes: microVM, LXC, QEMU/KVM, containers;
- service products: Jellyfin, Samba, identity systems;
- hardware and execution hosts;
- future CI orchestrators and runners.

Track the selected adapter and, where useful, its execution scope, provisioning authority, and version authority. Exact resolved versions belong in lockfiles or other executable configuration rather than duplicated prose.

Avoid two authoritative homes. Capability specs define role semantics; the Ops selection catalogue owns the concrete adapter name. When the adapter's external protocol is intentionally public, Behavior separately owns that observable contract.

## Minimal next step to explore

Consider a spec-only change adding the governed `ops/tooling` pair. Its spec would document the current role-to-tool selections; it need not introduce a new runtime catalogue file or application code. Because governed pairs require paired enforcement, `ops/tooling/enforcement.md` would point at existing sources of truth or use honest review where no deterministic check exists.

Questions to resolve before proposing it:

- Is `ops/tooling` limited to DevOps/DevX tools, or is it the first part of a broader `ops/selections` catalogue for services, runtimes, and hardware?
- Which direct tools are current truth versus only planned by active changes?
- Does the catalogue centrally own selections, requiring other Ops specs to become tool-neutral, or does it serve as a derived index of selections owned by focused pairs?
- Where should Specbase appear, given that `agents/spec-driven` owns the repo's Specbase instrument?

## Tooling conformance through Ops review

The initial `ops/tooling` pair does not need a custom lint or runtime catalogue artifact. Its paired enforcement should use an honest review binding assigned to the existing `ops` review lens.

The review compares changed implementation and configuration with the role-to-tool selections in `ops/tooling`. It should flag:

- a directly used operational tool that is absent from the catalogue;
- a competing adapter introduced for a role with a different selected tool;
- a selected tool used outside its declared scope;
- a tool replacement made without the corresponding Ops spec delta.

It should not flag incidental or transitive utilities, different tools assigned to distinct roles, explicitly declared coexistence during migration, or an intentional replacement accompanied by the catalogue update.

This preserves plane ownership:

- `ops/tooling` owns the role-to-adapter selection policy;
- its enforcement points the claim at the `ops` review lens;
- `agents/review-panel` owns the instrument that performs the review.

Automation can be added later if repeated drift justifies a tooling-conformance lint. Such a lint should detect undeclared role selections rather than attempt to inventory every executable installed on an operator machine or present in a package closure.
