## 1. Declare the bounded North York route

- [ ] 1.1 Extend the NetBird site module to resolve a unique enrolled router peer, manage its dedicated router-group membership, and declare a feature-gated `netbird_network_router` with explicit metric and masquerading so activation and rollback use source-controlled toggles.
- [ ] 1.2 Add a dedicated North York resource destination group and an explicit administrator peer source group without using a catch-all group.
- [ ] 1.3 Add one enabled administrator-to-North-York-resource policy with no reverse initiation, DNS object, NetBird SSH rule, user/service tier, or Scarborough declaration.
- [ ] 1.4 Fail planning when the selected router peer is absent, duplicated, disconnected, or inconsistent with the North York site data.

## 2. Prepare the OPNsense routed firewall boundary

- [ ] 2.1 Extend the reusable OPNsense NetBird role with a source-controlled activation toggle and persistent rule limited to ingress `wt0`, the selected NetBird overlay source alias, and the `10.10.10.0/24` North York LAN destination declared in Estate.
- [ ] 2.2 Reject WAN attachment, any/any source-destination pairs, unrelated interfaces, and implicit rule activation.
- [ ] 2.3 Implement savepoint creation, management-path checks, conditional commit, and automatic revert around route-rule activation.

## 3. Deliver static and live evidence

- [ ] 3.1 Extend `tests/iac/netbird-static-check` and the inherited `tests/iac/netbird-contracts.bats` from baseline-only assertions to phase-aware fixtures that accept the declared activated router/policy while still rejecting unrelated resources.
- [ ] 3.2 Extend `tests/ansible/opnsense-netbird-contracts.bats` to verify the active rule's interface, source, destination, ownership, and absence of broader exposure.
- [ ] 3.3 Implement `tests/verify/netbird-routing.bats` with bounded route, ICMP, and TCP probes from an explicitly selected authorized NetBird peer to safe Estate-derived North York targets, and add explicit cross-platform probe tools/adapters to the deployed verification runner runtime.
- [ ] 3.4 Write `docs/operations/netbird-routing.md` with activation, non-admin negative-access, savepoint commitment, rollback, and sanitized evidence procedures.
- [ ] 3.5 Link all Service, Estate, Configuration, and Lifecycle bindings to their native sources; update `tests/specbase/enforcement-observations.json` atomically for every added, replaced, and removed automated binding; execute static sources and Estate review before live activation and record results.

## 4. Activate and verify North York routing

- [ ] 4.1 Before adding/enabling activation declarations, confirm the existing North York OpenTofu baseline has a refresh-only no-change plan; then confirm encrypted state backup, final no-change enrollment playbook, connected unique router peer, local OPNsense management, and accepted activation plan before mutation.
- [ ] 4.2 Create the OPNsense firewall savepoint and enable the bounded `wt0` rule through Ansible while continuously verifying local management.
- [ ] 4.3 Apply the OpenTofu router-group membership, Network router assignment, masquerading, resource group, and administrator policy.
- [ ] 4.4 Run the authorized Bats probes and documented negative probe from a connected non-administrator peer, exercise ordinary local-LAN continuity and OPNsense administration, and confirm sanitized NetBird/OPNsense edge logs remain available; revert activation if any outcome is wrong.
- [ ] 4.5 Cancel the firewall rollback only after every check passes, then back up encrypted state and require final no-change OpenTofu and Ansible runs.

## 5. Prove rollback and close Stack 1

- [ ] 5.1 Exercise the rollback order through the declared source-controlled toggles: disable policy, remove or disable router assignment, prove routed access is gone, then disable the OPNsense pass rule while preserving peer enrollment, OPNsense administration, and ordinary local-LAN operation.
- [ ] 5.2 Reapply the accepted activation after the rollback drill, repeat positive/negative checks, and record only sanitized results.
- [ ] 5.3 Run normal repository and strict projected-stack Specbase validation and record the results.
- [ ] 5.4 Confirm Stack 1 leaves DNS, DHCP, PKI, Scarborough, application identity, and public ingress unchanged.
