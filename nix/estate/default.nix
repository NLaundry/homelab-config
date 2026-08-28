{ lib, registry ? import ./registry.nix }:

let
  evaluated = lib.evalModules {
    modules = [
      (import ./schema.nix { inherit lib; })
      { estate = registry; }
    ];
  };

  rawModel = evaluated.config.estate;
  model = builtins.deepSeq rawModel rawModel;
  safeId = id: builtins.match "^[A-Za-z][A-Za-z0-9_-]*$" id != null;
  names = builtins.attrNames;
  has = set: key: builtins.hasAttr key set;
  sortStrings = builtins.sort (a: b: a < b);
  canonicalReferences = values: sortStrings (lib.unique values);
  duplicateReferences = values:
    sortStrings (builtins.filter (value:
      builtins.length (builtins.filter (candidate: candidate == value) values) > 1
    ) (lib.unique values));

  sortById = builtins.sort (a: b: a.id < b.id);
  node = kind: key: {
    id = "${kind}:${key}";
    inherit kind key;
  };
  edge = kind: from: to: {
    id = "${kind}:${from}->${to}";
    inherit kind from to;
  };

  nodes = sortById (
    (map (node "site") (names model.sites))
    ++ (map (node "host") (names model.hosts))
    ++ (map (node "workload") (names model.workloads))
    ++ (map (node "state") (names model.states))
  );

  edges = sortById (
    (lib.concatMap (hostName:
      [ (edge "located-at" "host:${hostName}" "site:${model.hosts.${hostName}.site}") ]
    ) (names model.hosts))
    ++ (lib.concatMap (workloadName:
      map (hostName: edge "runs" "host:${hostName}" "workload:${workloadName}")
        (canonicalReferences model.workloads.${workloadName}.placements)
    ) (names model.workloads))
    ++ (lib.concatMap (workloadName:
      map (stateName: edge "consumes" "workload:${workloadName}" "state:${stateName}")
        (canonicalReferences model.workloads.${workloadName}.state)
    ) (names model.workloads))
    ++ (lib.concatMap (stateName:
      map (hostName: edge "owns" "host:${hostName}" "state:${stateName}")
        (canonicalReferences model.states.${stateName}.owners)
    ) (names model.states))
  );

  graph = {
    schemaVersion = 1;
    inherit nodes edges;
  };

  violation = code: subject: expected: observed: {
    inherit code subject expected observed;
  };

  unsafeIdViolations = lib.concatMap (kind:
    map (key: violation "unsafe-node-id" "${kind}:${key}" "safe-logical-id" [ key ])
      (builtins.filter (key: !(safeId key)) (names model.${kind + "s"}))
  ) [ "site" "host" "workload" "state" ];

  hostViolations = lib.concatMap (hostName:
    let site = model.hosts.${hostName}.site; in
    lib.optional (!(has model.sites site))
      (violation "unknown-host-site" "host:${hostName}" "declared-site" [ site ])
  ) (names model.hosts);

  workloadViolations = lib.concatMap (workloadName:
    let
      workload = model.workloads.${workloadName};
      placementCount = builtins.length workload.placements;
      placements = sortStrings workload.placements;
      stateDependencies = sortStrings workload.state;
      duplicateState = duplicateReferences workload.state;
    in
    (lib.optional (placementCount != 1)
      (violation "workload-placement-count" "workload:${workloadName}" "exactly-one-host" placements))
    ++ (map (hostName:
      violation "unknown-workload-host" "workload:${workloadName}" "declared-host" [ hostName ]
    ) (builtins.filter (hostName: !(has model.hosts hostName)) (canonicalReferences placements)))
    ++ (map (stateName:
      violation "unknown-workload-state" "workload:${workloadName}" "declared-state" [ stateName ]
    ) (builtins.filter (stateName: !(has model.states stateName)) (canonicalReferences stateDependencies)))
    ++ (lib.optional (duplicateState != [ ])
      (violation "duplicate-workload-state" "workload:${workloadName}"
        "unique-state-references" duplicateState))
  ) (names model.workloads);

  stateViolations = lib.concatMap (stateName:
    let
      state = model.states.${stateName};
      ownerCount = builtins.length state.owners;
      owners = sortStrings state.owners;
    in
    (lib.optional (ownerCount != 1)
      (violation "state-owner-count" "state:${stateName}" "exactly-one-host" owners))
    ++ (map (hostName:
      violation "unknown-state-owner" "state:${stateName}" "declared-host" [ hostName ]
    ) (builtins.filter (hostName: !(has model.hosts hostName)) (canonicalReferences owners)))
  ) (names model.states);

  violationKey = item:
    "${item.code}|${item.subject}|${builtins.toJSON item.observed}";
  violations = builtins.sort (a: b: violationKey a < violationKey b) (
    unsafeIdViolations ++ hostViolations ++ workloadViolations ++ stateViolations
  );

  indexById = items: builtins.listToAttrs (map (item: {
    name = item.id;
    value = item;
  }) items);

  diffItems = before: after:
    let
      old = indexById before;
      new = indexById after;
      oldIds = names old;
      newIds = names new;
      shared = builtins.filter (id: has new id) oldIds;
    in
    {
      added = map (id: new.${id}) (builtins.filter (id: !(has old id)) newIds);
      removed = map (id: old.${id}) (builtins.filter (id: !(has new id)) oldIds);
      changed = map (id: {
        inherit id;
        before = old.${id};
        after = new.${id};
      }) (builtins.filter (id: old.${id} != new.${id}) shared);
    };

  diff = before: after: {
    nodes = diffItems before.nodes after.nodes;
    edges = diffItems before.edges after.edges;
  };
in
{
  inherit model graph violations diff;
  valid = violations == [ ];
}
