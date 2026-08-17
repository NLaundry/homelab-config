## Why

The repository can evaluate and deploy the NAS, but it has no small, consistent operation surface for a complete non-live test gate or repeatable checks against a deployed homelab. The existing root `Makefile` already serves as the repository-wide entry point for deployment and validation, so that shared interface should be governed once by `ops.repository-operations` rather than repeated in each focused pair.

Establishing that structure and the testing operations now lets later changes harden one existing spec pair at a time without inventing a runner or restating the Makefile contract for every capability.

## What Changes

- Add an `ops.repository-operations` contract: the repository's root `Makefile` declares an operation registry and exposes each registered operation as a documented, same-named phony target.
- Add an `ops.testing` contract with three deliberately distinct operations:
  - `lint` strictly validates current governed specs and evaluates the flake without exercising tests or live homelab services.
  - `test` runs every registered non-live phase, including repository harness, tooling, agent-instrument, current-binding, and isolated NixOS VM evidence; Linux/KVM execution initially targets the physical NAS store directly.
  - `verify` independently invokes the Bats live-verification entry point; this foundation adds no mutating live check, while repeatability rules remain deferred.
- Adopt the NixOS test driver for isolated system tests and consume the shared Nix-packaged Bats tool for harness and live verification.
- Keep the remote test store replaceable so a future dedicated testing/CI host can take over without changing the operation contract.
- Add an `architecture.testing-isolation` contract that keeps candidate systems in disposable guests, keeps the execution host compute-only, and excludes test traffic from the physical LAN.
- **BREAKING** Rename the existing temporary physical activation operation from `test` to `try`.
- **BREAKING** Replace the existing `check` operation with `lint`.
- Modify `ops.deployment` so it defines the deployment operation set and deployment inputs, while `ops.repository-operations` owns the common Makefile interface.
- Make successful `try` and `deploy` activations run the default deployed verification suite as a postcondition; verification failure makes the operation fail and reports that activation is not rolled back.
- Leave test-writing quality rules and evidence for individual NAS requirements to later stacked changes.

## Planes

### Architecture

- `architecture.testing-isolation`: the enduring boundary between disposable test subjects, their compute provider, and the physical homelab LAN (new).

### Ops

- `ops.repository-operations`: the root Makefile operation registry and common repository operation surface (new).
- `ops.testing`: selected test runners, the complete non-live phase registry, remote-store selection, and independently runnable `lint`/`test`/`verify` semantics (new).
- `ops.deployment`: deployment operation vocabulary after temporary activation moves to `try`, including overridable deployment inputs and post-activation verification (modified).

No behavioral truth changes in this foundation. Later changes will bind concrete VM and Bats tests to the existing behavioral pairs they actually exercise.

## Spec pairs

- `architecture.testing-isolation` -> paired enforcement through the VM fixture and operation-boundary conformance source.
- `ops.repository-operations` -> paired enforcement through one generic root Makefile registry/surface conformance source.
- `ops.testing` -> paired enforcement through executable sources for current-spec validation, complete non-live phase dispatch, remote-store selection, isolated VM execution, and standalone live-runner failure propagation.
- `ops.deployment` -> paired enforcement through deployment-operation expansion and post-activation sequencing checks plus the existing manual end-to-end deployment procedure.

## Impact

- Affects `Makefile`, `flake.nix`, the initial `tests/` harness, and operator documentation.
- Builds on `establish-reproducible-repository-tooling` for Bats and shared operator commands, while adding task-specific harness/verification entry points and a NixOS VM test derivation executed in a remote Linux/KVM store.
- Uses the physical NAS store as the initial execution destination; no candidate configuration is activated on that host by the `test` operation.
- Targets the remote store from the foreground Nix client because macOS denies daemon-owned SSH connections used by `--builders`; this changes only test-store coordination, not the fixed derivation or isolation boundary.
- Builds on the archived `repair-specbase-agent-drift` change, so current-spec validation and coverage start green.
- Changes existing local commands: callers of `make check` and temporary-activation `make test` must use `make lint` and `make try` respectively.
- Establishes `make test` as the eventual automation/CI entry point for every safe non-live phase and makes `make verify` both an independent health check and the postcondition of immediate activation operations.
