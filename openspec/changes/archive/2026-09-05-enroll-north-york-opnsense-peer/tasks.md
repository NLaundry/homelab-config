## 1. Implement bounded enrollment

- [x] 1.1 Add one North York OPNsense NetBird playbook that reuses the existing inventory, pinned collection, SecretSpec scope, and trusted TLS certificate; verify syntax with dummy credentials.
- [x] 1.2 Implement a default read-only preflight for the recorded compatible installation and the plugin settings, authentication, service, and status APIs; verify it performs no mutation.
- [x] 1.3 Add separately gated preparation of essential peer settings with NetBird DNS, SSH, and route acceptance disabled; leave setup-key entry and Connect to the official OPNsense UI without assigning an interface or firewall state.

## 2. Verify and document

- [x] 2.1 Replace the draft enrollment runbook with concise preflight, hidden setup-key input, enrollment, key deletion, idempotence, and disconnect instructions.
- [x] 2.2 Add one `tests/ansible/opnsense-static-check` command for isolated collection installation, syntax validation, secret suppression, and absence of interface, firewall, routing activation, DNS takeover, setup-key handling, and Scarborough declarations; verify it passes in the Nix shell.
- [x] 2.3 Run the live read-only preflight and confirm the exact installed plugin/API contract, a disconnected-or-unique local identity, and no North York Network router assignment.
  - Result: settings, authentication, service, and status GET endpoints passed; the status API returned the installed controller's disconnected empty response; NetBird contained no candidate OPNsense peer and the North York Network had zero routers.

## 3. Enroll at the operator checkpoint

- [x] 3.1 After an administrator creates one no-auto-group, one-use setup key, prepare bounded settings, connect through the official OPNsense UI, and delete the key after success or failure; verify exactly one intended NetBird peer is connected and the Network remains unrouted.
  - Result: peer `dae4tpjl0ubs73b6migg` connected; the setup key was deleted; the North York Network retained zero routers and zero policies.
- [x] 3.2 Run the default playbook again without a key and require no enrollment change, then run `make check` and `openspec validate enroll-north-york-opnsense-peer --strict`.
  - Result: the no-key playbook reported `changed=0 failed=0`; the static check, Nix evaluation, strict OpenSpec validation, and live connected/unrouted check passed.
