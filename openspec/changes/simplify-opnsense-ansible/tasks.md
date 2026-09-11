## 1. Establish the compact OPNsense configuration surface

- [x] 1.1 Consolidate North York OPNsense desired values into a small site variable file and retain only shared connection, TLS, and SecretSpec wiring; verify all playbooks pass `ansible-playbook --syntax-check`.
- [x] 1.2 Confirm the pinned collection's ACME and Dnsmasq module behavior against OPNsense 26.7.3, including which singleton operations still need the raw API; verify the chosen module inputs in check mode without live writes.
- [x] 1.3 Confirm the installed os-netbird enrollment API and setup-key input path; verify either a supported raw API request shape or a documented manual-enrollment failure path, without exposing the setup key.

## 2. Implement ACME bootstrap and routine configuration

- [x] 2.1 Replace the custom ACME identity planner with native collection resources for the custom-CA account, account registration, HTTP-01 validation, WebGUI reload action, and certificate; verify missing objects are planned for creation and unchanged objects are idempotent.
- [x] 2.2 Add the explicit initial issuance operation and native renewal schedule configuration, using a narrow raw API call only if the collection has no issuance action; verify the playbook fails on a rejected operation and does not select a self-signed fallback.
- [x] 2.3 Preserve the existing legacy/private transport transition for certificate bootstrap and routine runs; verify the bootstrap and routine commands use the intended trust bundle and no credentials appear in output.

## 3. Implement Dnsmasq bootstrap and routine configuration

- [x] 3.1 Replace the DNS inspection, historical lease, deletion-planning, recovery, and custom domain-planning tasks with direct desired-state operations for Dnsmasq settings, reservations, ranges, and domain overrides; verify routine check mode reports only intended changes.
- [x] 3.2 Add the explicit initial Dnsmasq activation/resolver handoff path while keeping routine runs from enabling or disabling services implicitly; verify the bootstrap is visibly separate and the routine playbook leaves an already-correct router unchanged.
- [x] 3.3 Keep only DNS firewall access required by the declared network paths; do not retain a Guest-specific rule without a testable Guest client path, and verify the supported core paths with `tests/verify/dns.bats`.

## 4. Implement NetBird bootstrap and routing configuration

- [x] 4.1 Remove the saved-configuration download, XML parser, and custom interface-boundary verification; implement the tested os-netbird enrollment path or the explicit manual prerequisite for unsupported plugin versions; verify no setup key is logged.
- [x] 4.2 Keep only the desired NetBird plugin routing settings and OPNsense firewall rule in the routine role, leaving control-plane resources in OpenTofu; verify repeated check-mode and apply runs converge without duplicate rules.

## 5. Use the existing verification suite

- [x] 5.1 Align `tests/verify/dns.bats` with the desired core DNS records and retain its estate-derived UDP and TCP checks for NAS, router, and CA; do not add DHCP or Guest-path probes without a real client path.
- [x] 5.2 Retain `tests/verify/pki.bats` as the internal-CA acceptance probe for router HTTPS trust, issuer, SAN, renewal window, CA health, and intermediate identity.
- [x] 5.3 Simplify `tests/verify/control-plane.bats` so its OPNsense check uses a direct read-only API probe instead of invoking the Ansible credential-preflight playbook; keep NetBird control-plane connectivity under its existing SecretSpec scope.
- [x] 5.4 Add `tests/verify/routing.bats` only for explicit off-LAN inputs, checking route selection and a real routed service connection; verify the Nix runner discovers the file automatically.
- [ ] 5.5 Run each routine playbook twice during implementation verification and require no changes on the second run; keep this as a convergence check, not a substitute for the live behavior probes.

## 6. Remove obsolete ceremony and validate the replacement

- [x] 6.1 Remove retired enrollment, migration, recovery, custom filter, reapply, and runtime-verification paths that are no longer referenced; verify no playbook or documentation references the removed interfaces.
- [x] 6.2 Update Ansible and operations documentation to describe bootstrap, routine configuration, trust transitions, and test-suite acceptance; verify every documented command exists and runs syntax checks.
- [ ] 6.3 Run repository validation, Ansible syntax checks, and the targeted live verification probes after an explicitly authorized activation; verify ACME, Dnsmasq, DHCP, and NetBird outcomes independently.
