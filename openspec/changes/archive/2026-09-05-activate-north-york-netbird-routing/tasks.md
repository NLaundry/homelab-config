## 1. Implement minimal routing

- [x] 1.1 Confirm the administrator peer IDs, permitted traffic, and off-LAN test target with the operator; inspect the connected OPNsense peer and effective policies/routes and record the selected boundary before activation.
- [x] 1.2 Extend the existing root with direct OPNsense router assignment, masquerading, an explicit metric, one administrator group, and a one-way policy using the existing LAN resource group; verify formatting, locked initialization, and OpenTofu validation succeed.
- [x] 1.3 Update only required OPNsense plugin routing settings through the existing Ansible path, preserving DNS/SSH disablement and built-in firewall integration; verify syntax and read-only compatibility before mutation, and stop if manual interface or firewall configuration is required.

## 2. Consolidate useful checks

- [x] 2.1 Replace `tests/iac/netbird-static-check` and `tests/ansible/opnsense-static-check` with `tests/verify/iac-connectors.bats`; update current references, verify independently selected authenticated NetBird/OPNsense reads and a bounded routed-service check, and report unavailable off-LAN context without claiming success.
- [x] 2.2 Shorten `docs/operations/netbird-routing.md` to direct scoped commands, connector usage, normal tool validation, and policy/router disablement rollback; remove stale module, router-group, savepoint, backup, and drill instructions.

## 3. Activate with approval

Progress: `NY-Access` now contains the approved iPhone and MacBook peers. One direct OPNsense router and one LAN policy were applied. Plugin sync succeeded with a 120-second timeout; repeat Ansible execution reported `changed=0 failed=0` and OpenTofu reported no changes. Both API connector tests, Nix evaluation, and strict OpenSpec validation passed. The operator confirmed the MacBook was on a cellular hotspot when `nc -vz -G 5 10.10.10.11 445` succeeded twice. This is manual off-LAN SMB connection evidence, not an execution of the routed Bats case. Authenticated OPNsense reads confirmed management remained available. Unauthorized denial was reviewed through configuration, not measured with a separate non-member peer.

- [x] 3.1 Obtain explicit live activation approval and review one normal plan; apply only the selected router, administrator policy/group, and plugin changes, then verify the approved LAN service from an off-LAN NetBird peer and confirm local management still works. Withdraw activation on failure; report policy review separately from unperformed denial probes.
- [x] 3.2 Confirm final no-change OpenTofu/Ansible reconciliation, run the connector checks, `make check`, and strict OpenSpec validation, and record concise results without credentials or full state.
