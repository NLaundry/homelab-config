## 1. Establish reusable OPNsense Ansible control

- [ ] 1.1 Pin `oxlorg.opnsense` in the Ansible collection requirements and add repository commands for isolated collection installation and static validation.
- [ ] 1.2 Reshape `ansible/inventory.yml` and variables to identify only the North York site/router while keeping connection details and site data outside reusable role tasks; preserve the existing `.all.children.nas.hosts.nasty` lookup or update every deployed-verification consumer atomically.
- [ ] 1.3 Create `ansible/roles/opnsense_netbird_peer/` and a bounded North York enrollment playbook using dedicated collection modules first and documented raw API calls only for uncovered official endpoints.
- [ ] 1.4 Add inventory-to-Estate consistency checks for the North York router identity and management address.

## 2. Implement compatibility and recovery preflight

- [ ] 2.1 Write `docs/operations/opnsense-netbird-enrollment.md` with read-only preflight, configuration backup, local management proof, enrollment, verification, idempotence, and rollback procedures.
- [ ] 2.2 Implement read-only tasks that query firmware, `os-netbird` availability, required plugin/core API endpoints, interface state, current DNS/DHCP services, backup capability, and management reachability.
- [ ] 2.3 Fail before mutation unless the installed release supports the official plugin and every required API round-trip; do not fall back to direct `config.xml` editing.
- [ ] 2.4 Store a complete pre-change OPNsense configuration backup in protected external storage, validate its integrity/importability without mutating the router, and record only a sanitized identifier/hash; also record either physical presence or both a tested local-LAN administration path and working console recovery.

## 3. Configure the bounded NetBird peer

- [ ] 3.1 Install `os-netbird`, enable the service, and configure the selected WireGuard, firewall, LAN-access, and route-acceptance settings through the supported OPNsense API.
- [ ] 3.2 Explicitly disable NetBird-managed DNS, NetBird SSH, root SSH, SFTP, and local/remote SSH forwarding.
- [ ] 3.3 Assign `wt0` without an address or active overlay-to-LAN pass rule; create only role-owned aliases and disabled rule preparation under a firewall savepoint.
- [ ] 3.4 Verify existing LAN management and unrelated router services immediately after package, settings, interface, and firewall stages; revert the savepoint on failure.

## 4. Enroll once and retire the setup key

- [ ] 4.1 Implement the enrollment command to detect an existing intended local/remote peer before creating any key and to stop on duplicate or ambiguous identity.
- [ ] 4.2 Implement one guarded enrollment operation that creates one no-auto-group, one-use setup key through the NetBird API, passes it through volatile secret handling to the no-log Ansible task, invokes the plugin authentication/up APIs, and retires the key in the same operation's unconditional cleanup on success, failure, or interruption.
- [ ] 4.3 Extend `tests/secrets/contracts.bats` to exercise the guarded operation's success/failure cleanup and verify it cannot persist a setup key in Git, SOPS, logs, or OpenTofu state.
- [ ] 4.4 Verify `wt0`, NetBird service health, management connectivity, unique remote peer identity, absence of a North York Network router assignment, and a bounded negative probe proving selected LAN targets are still unreachable through NetBird.
- [ ] 4.5 Run the same playbook again and require no new setup key, peer, package, interface, or managed-setting change.

## 5. Deliver verification and validate rollback

- [ ] 5.1 Implement `tests/ansible/opnsense-static-check` for collection installation, inventory parsing, role validation, syntax checking, and Estate consistency with dummy credential paths.
- [ ] 5.2 Implement `tests/ansible/opnsense-netbird-contracts.bats` for Ansible-only OPNsense ownership, approved endpoint use, bounded plugin settings, secret suppression, setup-key retirement, North York-only scope, and no effective routed-LAN rule.
- [ ] 5.3 Run `tests/ansible/opnsense-static-check`, `bats tests/ansible/opnsense-netbird-contracts.bats`, and `bats tests/secrets/contracts.bats` in the Nix development shell; record results and the enrollment runbook's manual observations without secret values.
- [ ] 5.4 Execute or dry-run the documented rollback far enough to prove NetBird can be disconnected and role-owned state removed without losing local management; restore the intended enrolled prefix afterward if exercised live.
- [ ] 5.5 Run `make check` for Nix evaluation and separately run `openspec validate enroll-north-york-opnsense-peer --strict`; record the results before routing activation. `make check` does not run OpenSpec or shell tests.
