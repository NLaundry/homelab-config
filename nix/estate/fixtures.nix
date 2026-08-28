{ lib }:

let
  baseRegistry = import ./registry.nix;
  mk = registry: import ./default.nix { inherit lib registry; };
  base = mk baseRegistry;

  withCompute = lib.recursiveUpdate baseRegistry {
    hosts.compute.site = "home";
  };

  registries = {
    zeroPlacement = lib.recursiveUpdate baseRegistry {
      workloads.file-sharing.placements = [ ];
    };
    multiplePlacement = lib.recursiveUpdate withCompute {
      workloads.file-sharing.placements = [ "nas" "compute" ];
    };
    unknownSite = lib.recursiveUpdate baseRegistry {
      hosts.nas.site = "missing";
    };
    unknownHost = lib.recursiveUpdate baseRegistry {
      workloads.file-sharing.placements = [ "missing" ];
    };
    unknownState = lib.recursiveUpdate baseRegistry {
      workloads.file-sharing.state = [ "mediaBin" "missing" ];
    };
    duplicateState = lib.recursiveUpdate baseRegistry {
      workloads.file-sharing.state = [ "mediaBin" "mediaBin" "smolBoy" ];
    };
    ownerlessState = lib.recursiveUpdate baseRegistry {
      states.mediaBin.owners = [ ];
    };
    multipleOwners = lib.recursiveUpdate withCompute {
      states.mediaBin.owners = [ "nas" "compute" ];
    };
    hostRemoval = baseRegistry // {
      hosts = builtins.removeAttrs baseRegistry.hosts [ "nas" ];
    };
    unsafeId = lib.recursiveUpdate baseRegistry {
      sites."bad id" = { };
    };
  };

  evaluated = lib.mapAttrs (_: mk) registries;
  graphs = lib.mapAttrs (_: value: value.graph) evaluated;
  violations = lib.mapAttrs (_: value: value.violations) evaluated;
  v = code: subject: expected: observed: {
    inherit code subject expected observed;
  };
  expectedViolations = {
    zeroPlacement = [
      (v "workload-placement-count" "workload:file-sharing" "exactly-one-host" [ ])
    ];
    multiplePlacement = [
      (v "workload-placement-count" "workload:file-sharing" "exactly-one-host" [ "compute" "nas" ])
    ];
    unknownSite = [
      (v "unknown-host-site" "host:nas" "declared-site" [ "missing" ])
    ];
    unknownHost = [
      (v "unknown-workload-host" "workload:file-sharing" "declared-host" [ "missing" ])
    ];
    unknownState = [
      (v "unknown-workload-state" "workload:file-sharing" "declared-state" [ "missing" ])
    ];
    duplicateState = [
      (v "duplicate-workload-state" "workload:file-sharing" "unique-state-references" [ "mediaBin" ])
    ];
    ownerlessState = [
      (v "state-owner-count" "state:mediaBin" "exactly-one-host" [ ])
    ];
    multipleOwners = [
      (v "state-owner-count" "state:mediaBin" "exactly-one-host" [ "compute" "nas" ])
    ];
    hostRemoval = [
      (v "unknown-state-owner" "state:mediaBin" "declared-host" [ "nas" ])
      (v "unknown-state-owner" "state:smolBoy" "declared-host" [ "nas" ])
      (v "unknown-workload-host" "workload:file-sharing" "declared-host" [ "nas" ])
    ];
    unsafeId = [
      (v "unsafe-node-id" "site:bad id" "safe-logical-id" [ "bad id" ])
    ];
  };

  reorderedRegistry = {
    states = {
      smolBoy.owners = [ "nas" ];
      mediaBin.owners = [ "nas" ];
    };
    workloads.file-sharing = {
      state = [ "smolBoy" "mediaBin" ];
      placements = [ "nas" ];
    };
    hosts.nas.site = "home";
    sites.home = { };
  };
  withComputeEstate = mk withCompute;
  movedWorkload = mk (lib.recursiveUpdate withCompute {
    workloads.file-sharing.placements = [ "compute" ];
  });
  movedOwnership = mk (lib.recursiveUpdate withCompute {
    states.mediaBin.owners = [ "compute" ];
  });

  diffs = {
    reorder = base.diff base.graph (mk reorderedRegistry).graph;
    nodeAddition = base.diff base.graph withComputeEstate.graph;
    nodeRemoval = withComputeEstate.diff withComputeEstate.graph base.graph;
    placementMove = withComputeEstate.diff withComputeEstate.graph movedWorkload.graph;
    ownershipChange = withComputeEstate.diff withComputeEstate.graph movedOwnership.graph;
  };
  empty = { added = [ ]; removed = [ ]; changed = [ ]; };

  invalidShapeEval = lib.evalModules {
    modules = [
      (import ./schema.nix { inherit lib; })
      {
        estate = lib.recursiveUpdate baseRegistry {
          sites.home.address = "configuration-detail-is-forbidden";
        };
      }
    ];
  };
  invalidShapeAccepted = (builtins.tryEval
    (builtins.deepSeq invalidShapeEval.config.estate true)).success;

  diagnosticChecks = lib.mapAttrs
    (name: actual: actual == expectedViolations.${name}) violations;
  diffChecks = {
    reorderIsEmpty = diffs.reorder == { nodes = empty; edges = empty; };
    nodeAdditionIsScoped =
      diffs.nodeAddition.nodes.added == [ { id = "host:compute"; key = "compute"; kind = "host"; } ]
      && diffs.nodeAddition.nodes.removed == [ ]
      && diffs.nodeAddition.nodes.changed == [ ]
      && (map (item: item.id) diffs.nodeAddition.edges.added)
        == [ "located-at:host:compute->site:home" ]
      && diffs.nodeAddition.edges.removed == [ ]
      && diffs.nodeAddition.edges.changed == [ ];
    nodeRemovalIsScoped =
      diffs.nodeRemoval.nodes.added == [ ]
      && diffs.nodeRemoval.nodes.removed == [ { id = "host:compute"; key = "compute"; kind = "host"; } ]
      && diffs.nodeRemoval.nodes.changed == [ ]
      && diffs.nodeRemoval.edges.added == [ ]
      && (map (item: item.id) diffs.nodeRemoval.edges.removed)
        == [ "located-at:host:compute->site:home" ]
      && diffs.nodeRemoval.edges.changed == [ ];
    placementMoveIsScoped =
      diffs.placementMove.nodes == empty
      && (map (item: item.id) diffs.placementMove.edges.removed)
        == [ "runs:host:nas->workload:file-sharing" ]
      && (map (item: item.id) diffs.placementMove.edges.added)
        == [ "runs:host:compute->workload:file-sharing" ]
      && diffs.placementMove.edges.changed == [ ];
    ownershipChangeIsScoped =
      diffs.ownershipChange.nodes == empty
      && (map (item: item.id) diffs.ownershipChange.edges.removed)
        == [ "owns:host:nas->state:mediaBin" ]
      && (map (item: item.id) diffs.ownershipChange.edges.added)
        == [ "owns:host:compute->state:mediaBin" ]
      && diffs.ownershipChange.edges.changed == [ ];
  };
  edgeIds = map (item: item.id) base.graph.edges;
  checks = diagnosticChecks // diffChecks // {
    productionClean = base.valid;
    invalidShapeRejected = !invalidShapeAccepted;
    uniqueProductionEdgeIds = builtins.length edgeIds == builtins.length (lib.unique edgeIds);
  };
in
{
  inherit baseRegistry graphs violations expectedViolations diffs checks;
  all = lib.all (value: value) (builtins.attrValues checks);
}
