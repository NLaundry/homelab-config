#!/usr/bin/env bats

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  FLAKE_REF=${HOMELAB_FLAKE_REF:-"path:$ROOT"}
  CURRENT_SYSTEM=$(nix eval --impure --raw --expr builtins.currentSystem)
}

nix_json() {
  nix eval --no-update-lock-file --json "$FLAKE_REF#$1"
}

@test "schema-export: production graph is normalized, bounded, and JSON-safe" {
  graph=$(nix_json lib.estateGraph)
  run jq -e '
    .schemaVersion == 1 and
    (.nodes | map(.id)) == ["host:nas","site:home","state:mediaBin","state:smolBoy","workload:file-sharing"] and
    (.nodes | all((keys | sort) == ["id","key","kind"])) and
    (.edges | length) == 6 and
    (.edges | all((keys | sort) == ["from","id","kind","to"])) and
    (.edges | map(.id)) == ( .edges | map(.id) | sort ) and
    (.edges | map(.id) | length) == (.edges | map(.id) | unique | length) and
    ([.nodes[].kind] | unique) == ["host","site","state","workload"]
  ' <<<"$graph"
  [ "$status" -eq 0 ]

  checks=$(nix_json lib.estateRegistry.fixtureChecks)
  summary=$(nix_json lib.estateRegistry.checkFailureSummary)
  run jq -e '.invalidShapeRejected == true' <<<"$checks"
  [ "$status" -eq 0 ]
  run jq -e --argjson graph "$graph" '
    .productionGraph == $graph and .productionViolations == [] and
    .failedFixtureChecks == {} and
    .fixtureViolations == .fixtureExpectedViolations and
    (.fixtureDiffs | has("nodeAddition") and has("nodeRemoval") and has("placementMove") and has("ownershipChange")) and
    (.missingObservationMutant.violations | length) == 2 and
    (.observedOnlyMutant.violations | length) == 2
  ' <<<"$summary"
  [ "$status" -eq 0 ]
}

@test "production-graph: current Estate relationships and cardinalities are clean" {
  graph=$(nix_json lib.estateGraph)
  violations=$(nix_json lib.estateRegistry.productionViolations)
  [ "$violations" = '[]' ]
  run jq -e '
    ([.edges[] | select(.kind=="located-at") | [.from,.to]] == [["host:nas","site:home"]]) and
    ([.edges[] | select(.kind=="runs") | [.from,.to]] == [["host:nas","workload:file-sharing"]]) and
    ([.edges[] | select(.kind=="consumes") | .to] == ["state:mediaBin","state:smolBoy"]) and
    ([.edges[] | select(.kind=="owns") | [.from,.to]] == [["host:nas","state:mediaBin"],["host:nas","state:smolBoy"]])
  ' <<<"$graph"
  [ "$status" -eq 0 ]
}

@test "validator-diagnostics: invalid fixtures emit exact structured violation arrays" {
  graphs=$(nix_json lib.estateRegistry.fixtureGraphs)
  violations=$(nix_json lib.estateRegistry.fixtureViolations)
  expected=$(nix_json lib.estateRegistry.fixtureExpectedViolations)
  checks=$(nix_json lib.estateRegistry.fixtureChecks)
  run jq -e 'all(.[]; . == true)' <<<"$checks"
  [ "$status" -eq 0 ]
  run jq -e --argjson expected "$expected" '. == $expected' <<<"$violations"
  [ "$status" -eq 0 ]
  run jq -e '
    [.duplicateState.edges[] | select(.kind=="consumes") | .id] == [
      "consumes:workload:file-sharing->state:mediaBin",
      "consumes:workload:file-sharing->state:smolBoy"
    ]
  ' <<<"$graphs"
  [ "$status" -eq 0 ]
}

@test "graph-diff: every node and relationship bucket is scoped and order-independent" {
  diffs=$(nix_json lib.estateRegistry.fixtureDiffs)
  run jq -e '
    (.reorder | [.nodes.added,.nodes.removed,.nodes.changed,.edges.added,.edges.removed,.edges.changed] | all(length==0)) and
    (.nodeAddition.nodes.added | map(.id)) == ["host:compute"] and
    (.nodeAddition.nodes.removed == [] and .nodeAddition.nodes.changed == []) and
    (.nodeAddition.edges.added | map(.id)) == ["located-at:host:compute->site:home"] and
    (.nodeAddition.edges.removed == [] and .nodeAddition.edges.changed == []) and
    (.nodeRemoval.nodes.removed | map(.id)) == ["host:compute"] and
    (.nodeRemoval.nodes.added == [] and .nodeRemoval.nodes.changed == []) and
    (.nodeRemoval.edges.removed | map(.id)) == ["located-at:host:compute->site:home"] and
    (.nodeRemoval.edges.added == [] and .nodeRemoval.edges.changed == []) and
    (.placementMove.nodes == {"added":[],"removed":[],"changed":[]}) and
    (.placementMove.edges.removed | map(.id)) == ["runs:host:nas->workload:file-sharing"] and
    (.placementMove.edges.added | map(.id)) == ["runs:host:compute->workload:file-sharing"] and
    .placementMove.edges.changed == [] and
    (.ownershipChange.nodes == {"added":[],"removed":[],"changed":[]}) and
    (.ownershipChange.edges.removed | map(.id)) == ["owns:host:nas->state:mediaBin"] and
    (.ownershipChange.edges.added | map(.id)) == ["owns:host:compute->state:mediaBin"] and
    .ownershipChange.edges.changed == []
  ' <<<"$diffs"
  [ "$status" -eq 0 ]
}

@test "reconciliation: evaluated NAS facts align and a controlled drift is diagnosed" {
  current=$(nix_json lib.estateRegistry.reconciliation)
  mutant=$(nix_json lib.estateRegistry.reconciliationMutant)
  observed_only=$(nix_json lib.estateRegistry.reconciliationObservedOnlyMutant)
  run jq -e '
    .valid == true and .violations == [] and
    .observed.hosts.nas.workloads == ["file-sharing"] and
    (.observed.hosts.nas.state | sort) == ["mediaBin","smolBoy"] and
    .limitations == [
      "evaluated-service-enablement-does-not-prove-physical-workload-placement",
      "evaluated-pool-selection-does-not-prove-disk-ownership-or-health",
      "point-in-time-observation-does-not-prove-exclusive-authority"
    ]
  ' <<<"$current"
  [ "$status" -eq 0 ]
  run jq -e '
    .valid == false and
    .violations == [
      {"code":"state-reconciliation-mismatch","expected":"selected-on-host:nas","observed":["smolBoy"],"subject":"state:mediaBin"},
      {"code":"workload-reconciliation-mismatch","expected":"enabled-on-host:nas","observed":[],"subject":"workload:file-sharing"}
    ] and
    .limitations == [
      "evaluated-service-enablement-does-not-prove-physical-workload-placement",
      "evaluated-pool-selection-does-not-prove-disk-ownership-or-health",
      "point-in-time-observation-does-not-prove-exclusive-authority"
    ]
  ' <<<"$mutant"
  [ "$status" -eq 0 ]
  run jq -e '
    .valid == false and
    .violations == [
      {"code":"unexpected-observed-state","expected":"no-owner-on-host:nas","observed":["nas"],"subject":"state:mediaBin"},
      {"code":"unexpected-observed-workload","expected":"no-placement-on-host:nas","observed":["nas"],"subject":"workload:file-sharing"}
    ] and
    .limitations == [
      "evaluated-service-enablement-does-not-prove-physical-workload-placement",
      "evaluated-pool-selection-does-not-prove-disk-ownership-or-health",
      "point-in-time-observation-does-not-prove-exclusive-authority"
    ]
  ' <<<"$observed_only"
  [ "$status" -eq 0 ]
}

@test "flake-check: Estate graph artifacts build without runtime activation" {
  run nix build --no-update-lock-file --no-link "$FLAKE_REF#checks.$CURRENT_SYSTEM.estate-registry"
  [ "$status" -eq 0 ]
}
