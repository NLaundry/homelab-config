{ lib, model, observed }:

let
  names = builtins.attrNames;
  has = set: key: builtins.hasAttr key set;
  canonical = values: builtins.sort (a: b: a < b) (lib.unique values);
  allHosts = canonical ((names model.hosts) ++ (names observed.hosts));

  expectedHost = hostName: {
    workloads = canonical (builtins.filter (workloadName:
      builtins.elem hostName model.workloads.${workloadName}.placements
    ) (names model.workloads));
    state = canonical (builtins.filter (stateName:
      builtins.elem hostName model.states.${stateName}.owners
    ) (names model.states));
  };
  observedHost = hostName:
    if has observed.hosts hostName then {
      workloads = canonical (observed.hosts.${hostName}.workloads or [ ]);
      state = canonical (observed.hosts.${hostName}.state or [ ]);
    } else { workloads = [ ]; state = [ ]; };

  expected = {
    hosts = builtins.listToAttrs (map (hostName: {
      name = hostName;
      value = expectedHost hostName;
    }) allHosts);
  };

  violation = code: subject: expectedValue: actual: {
    inherit code subject;
    expected = expectedValue;
    observed = actual;
  };

  hostViolations = lib.concatMap (hostName:
    let
      wanted = expectedHost hostName;
      actual = observedHost hostName;
      missingWorkloads = builtins.filter
        (name: !(builtins.elem name actual.workloads)) wanted.workloads;
      extraWorkloads = builtins.filter
        (name: !(builtins.elem name wanted.workloads)) actual.workloads;
      missingState = builtins.filter
        (name: !(builtins.elem name actual.state)) wanted.state;
      extraState = builtins.filter
        (name: !(builtins.elem name wanted.state)) actual.state;
    in
    (map (workloadName:
      violation "workload-reconciliation-mismatch" "workload:${workloadName}"
        "enabled-on-host:${hostName}" actual.workloads
    ) missingWorkloads)
    ++ (map (workloadName:
      violation "unexpected-observed-workload" "workload:${workloadName}"
        "no-placement-on-host:${hostName}" [ hostName ]
    ) extraWorkloads)
    ++ (map (stateName:
      violation "state-reconciliation-mismatch" "state:${stateName}"
        "selected-on-host:${hostName}" actual.state
    ) missingState)
    ++ (map (stateName:
      violation "unexpected-observed-state" "state:${stateName}"
        "no-owner-on-host:${hostName}" [ hostName ]
    ) extraState)
  ) allHosts;

  key = item: "${item.code}|${item.subject}|${builtins.toJSON item.observed}";
  violations = builtins.sort (a: b: key a < key b) hostViolations;
in
{
  inherit expected observed violations;
  valid = violations == [ ];
  limitations = [
    "evaluated-service-enablement-does-not-prove-physical-workload-placement"
    "evaluated-pool-selection-does-not-prove-disk-ownership-or-health"
    "point-in-time-observation-does-not-prove-exclusive-authority"
  ];
}
