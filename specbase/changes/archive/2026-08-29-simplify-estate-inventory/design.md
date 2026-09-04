## Context

The current Estate implementation uses six Nix files, a generated graph, semantic diffs, reconciliation, mutation fixtures, flake exports, and a large Bats suite to describe one site, one host, and one service. It does not drive deployment or broadly observe live topology. The useful requirement is a readable inventory that an operator can edit directly.

## Goals / Non-Goals

**Goals:**
- Make the entire current Estate understandable in one short YAML file.
- Record sites, hosts, host details, addresses, and service placement without generated graph concepts.
- Provide one obvious check command after editing.
- Remove code and claims that imply deployment or runtime reconciliation.

**Non-Goals:**
- Drive NixOS configuration from the inventory.
- Discover live hosts or services.
- Define a generic schema, graph API, diff engine, or migration framework.
- Require every possible host or service field up front.

## Decisions

### One flat inventory file

`estate.yaml` is a small mapping with `version`, `sites`, `hosts`, and `services`. A host references its site. A service references its host. Host records may contain practical details such as hostname, addresses, and storage. Service records may gain fields such as `url` when useful.

The file is descriptive operator inventory. NixOS remains authoritative for deployment and runtime configuration.

### No generated model

Remove `nix/estate/`, `lib.estateGraph`, the Estate flake check, reconciliation mutants, graph artifacts, and semantic diff code. Git already provides change history and review diffs for the YAML file.

### Small source contract

`tests/estate/inventory.bats` runs in the existing harness with `yq`. It makes three bounded assertions in one test:
- the file is valid YAML with version 1 and map-valued `sites`, `hosts`, and `services`;
- every host references an existing site and every service references an existing host;
- the current inventory records `home`, `nas`, the selected NAS address, and `file-sharing` on `nas`.

A failure exits non-zero and prints the failed `yq` expression. The check proves only inventory syntax and references; it does not prove deployment or live reachability.

### Simple update command

`make estate-check` runs only the focused inventory test. A comment at the top of `estate.yaml` tells maintainers to update it with relevant topology/address changes and run that command.

## Enforcement design

- Estate and Configuration inventory claims bind to `tests/estate/inventory.bats` because that source reads the actual YAML values.
- The Governance parse/shape claim binds to the same focused test.
- The update-in-the-same-change rule uses Governance review because automation cannot determine whether an omitted inventory edit was intentional.
- Existing NAS Estate review remains. Graph and reconciliation bindings are removed rather than replaced with weaker claims.

## Risks / Trade-offs

- [The YAML may drift from deployed reality] -> Label it as descriptive inventory, keep the update rule visible, and do not claim runtime proof.
- [The shape may evolve] -> Keep validation deliberately shallow so URLs and new details can be added without schema work.
- [An address exists in operational files too] -> Configuration owns the selected value; the inventory is its operator-facing catalogue, not deployment input.

## Migration Plan

1. Add `estate.yaml` and the focused inventory check.
2. Remove the typed Nix Estate implementation and flake surfaces.
3. Replace typed-graph specifications and bindings with the minimal inventory contract.
4. Run focused tests, the routine harness, strict Specbase validation, and flake evaluation.
5. Roll back by reverting this change; it does not activate or alter the NAS.
