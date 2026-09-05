## 1. Implement bounded enrollment

- [x] 1.1 Add one North York OPNsense NetBird playbook that reuses the existing inventory, pinned collection, SecretSpec scope, and trusted TLS certificate; verify syntax with dummy credentials.
- [x] 1.2 Implement a default read-only preflight for the recorded compatible installation and the plugin settings, authentication, service, and status APIs; verify it performs no mutation.
- [ ] 1.3 Add a separately gated enrollment block that configures only essential peer settings, keeps NetBird DNS and SSH disabled, consumes `NETBIRD_SETUP_KEY` under `no_log`, authenticates, and starts the service without assigning an interface or firewall state.

## 2. Verify and document

- [x] 2.1 Replace the draft enrollment runbook with concise preflight, hidden setup-key input, enrollment, key deletion, idempotence, and disconnect instructions.
- [ ] 2.2 Add one `tests/ansible/opnsense-static-check` command for isolated collection installation, syntax validation, secret suppression, and absence of interface, firewall, routing, DNS-takeover, setup-key persistence, and Scarborough declarations; verify it passes in the Nix shell.
- [x] 2.3 Run the live read-only preflight and confirm the exact installed plugin/API contract, a disconnected-or-unique local identity, and no North York Network router assignment.
  - Result: settings, authentication, service, and status GET endpoints passed; the status API returned the installed controller's disconnected empty response; NetBird contained no candidate OPNsense peer and the North York Network had zero routers.

## 3. Enroll at the operator checkpoint

- [ ] 3.1 After an administrator creates one no-auto-group, one-use setup key, run the gated enrollment and delete the key after success or failure; verify exactly one intended NetBird peer is connected and the Network remains unrouted.
- [ ] 3.2 Run the default playbook again without a key and require no enrollment change, then run `make check` and `openspec validate enroll-north-york-opnsense-peer --strict`.
