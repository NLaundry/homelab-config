## Context

See `proposal.md` and the three capability specs for the intended behavior. The current branch has three useful OPNsense concerns but implements them with separate full-state planners, custom filters, recovery transports, and runtime acceptance checks. The pinned `oxlorg.opnsense` collection provides native ACME account, validation, action, and certificate modules, plus Dnsmasq resource modules. It does not provide a NetBird module; NetBird operations therefore use the plugin API directly.

The router is a single North York OPNsense target. NetBird control-plane resources remain in `infra/terraform/netbird`. The internal CA remains hosted and operated by the step-ca configuration; OPNsense is an ACME client.

## Goals / Non-Goals

**Goals:**

- Make the desired OPNsense state easy to find and understand.
- Support explicit first-time bootstrap for Dnsmasq, ACME, and NetBird where the target APIs permit it.
- Keep routine runs idempotent and limited to owned settings and resources.
- Make Ansible responsible for API configuration success, not network acceptance.
- Use the existing `tests/verify` probes for DNS, certificate, CA, and routed-access acceptance.
- Preserve the useful ACME ownership boundary: OPNsense obtains and renews its own certificate from step-ca.

**Non-Goals:**

- Automating NetBird control-plane resources from Ansible.
- Building a generic multi-site OPNsense framework.
- Implementing historical ISC lease migration or automated rollback.
- Performing live DNS, DHCP, certificate, or off-LAN routing acceptance inside Ansible.
- Replacing the internal CA or moving CA private state onto OPNsense.

## Decisions

### Keep one role and playbook per router concern

Retain separate DNS, NetBird, and ACME roles/playbooks. This keeps changes independently runnable and avoids a single playbook whose ordering can unexpectedly change DHCP, overlay routing, and WebGUI certificates together.

Each concern has a small bootstrap path for first-time creation or activation and a routine path for repeat configuration. Bootstrap is explicit in the invocation; routine runs do not enable a disabled service or enroll a new identity as a side effect.

### Use native collection modules for ACME objects

Use the pinned collection's account, validation, action, and certificate modules to create or update named objects. Register the account against the configured custom ACME directory, create HTTP-01 validation and WebGUI reload automation, and configure the native renewal schedule. Use a narrowly scoped raw API operation only if the collection lacks the initial issue/renew action.

This replaces the custom ACME identity planner. Native object names and the collection's idempotent lookup are sufficient for this single router; duplicate or missing objects are operator errors to resolve, not inputs to a reconciliation engine.

### Use the collection for Dnsmasq resources and a minimal settings operation

Manage Dnsmasq general settings, hosts, ranges, and domain overrides through the pinned collection where its modules cover the operation. Use the raw API only for a singleton setting or service operation that the collection cannot express reliably. Desired records are stored as normal site data; omission is not a request to delete unrelated router state.

The initial resolver/DHCP transition is a clearly marked bootstrap operation. Routine runs only maintain an already-enabled Dnsmasq service and do not inspect historical ISC leases or implement a recovery transport.

### Treat NetBird enrollment as a bounded plugin operation

Keep NetBird settings and the required OPNsense firewall rule in the NetBird role. Add a bootstrap operation that passes a setup key from SecretSpec to the plugin only if the installed os-netbird version exposes a stable enrollment endpoint. If it does not, fail with a manual enrollment instruction and leave the routine routing path available for an already-enrolled peer.

Do not download or parse the full OPNsense configuration. The role will validate only the plugin state required to apply routing, and the test suite will establish whether the peer can route real traffic.

### Use standard Ansible execution semantics

Normal playbook execution applies desired configuration. `--check` provides a preview. API errors and unsuccessful save/reconfigure responses fail the task. Remove custom `apply_*`, `reapply_*`, `runtime_verified`, and post-apply readback state machines unless an individual API operation requires a minimal retry task.

### Match the existing verification suite

Keep tests read-only and behavioral, and fit them into the suite that already exists. The Nix verification runner discovers every `tests/verify/*.bats` file automatically, derives the core DNS and HTTPS context from `estate.yaml`, and supplies the normal system-plus-LaundryLab trust bundle.

- `tests/verify/dns.bats` remains the DNS acceptance probe. It currently checks the estate NAS, router, and CA records over both UDP and TCP. Do not invent DHCP or Guest-network tests without a real client path.
- `tests/verify/pki.bats` remains the certificate and CA probe. It checks normal HTTPS trust, router issuer/SAN/renewal window, CA health, and the commissioned intermediate.
- `tests/verify/control-plane.bats` remains the authenticated NetBird and OPNsense connectivity probe, but should not invoke a heavyweight Ansible preflight just to test the API connection.
- Add a focused `tests/verify/routing.bats` only for the missing off-LAN route selection and real service connection, using explicit opt-in target/interface inputs. The automatic runner will discover it.
- `tests/verify/nas.bats` remains unrelated to this change.

Ansible may report that OPNsense accepted a configuration request, but only these probes establish that the resulting service works. `make verify` is the suite entry point; no separate probe registration is needed.

## Risks / Trade-offs

- [Initial Dnsmasq activation can interrupt DHCP or DNS] -> Keep it in an explicit bootstrap path and require an independent router recovery path outside routine Ansible.
- [Initial ACME connection may encounter the router's old certificate] -> Run bootstrap through the currently trusted legacy transport, then use the LaundryLab root trust profile for routine runs.
- [The pinned Dnsmasq modules are marked unstable] -> Pin the collection, exercise the exact OPNsense version during implementation, and use a small raw API fallback only where required.
- [The os-netbird enrollment API may differ by plugin version] -> Detect/support the tested endpoint; otherwise stop and document the one-time UI enrollment instead of guessing an API.
- [Removing Ansible runtime checks reduces immediate feedback] -> Run `make verify` after approved changes; use the existing DNS, PKI, and control-plane probes plus the focused routing probe when its explicit inputs are available.
- [Names alone may not distinguish duplicate native ACME objects] -> Keep stable names/descriptions and fail on ambiguity rather than selecting an arbitrary object.

## Migration Plan

1. Capture the current desired North York values and retain an independent encrypted OPNsense backup.
2. Implement the compact roles while preserving the existing connection profiles and SecretSpec scopes.
3. Validate syntax and collection module inputs without contacting the router.
4. Run the bootstrap paths one at a time, beginning with the least disruptive prerequisite and using the appropriate legacy/private trust profile.
5. Run the existing and new behavioral probes after each approved activation.
6. Run routine playbooks repeatedly and require no changes on the second run.
7. Remove the retired planners, custom filters, recovery tasks, stale enrollment playbook, and obsolete documentation only after the replacement probes pass.

Rollback is operational rather than automatic: restore the encrypted OPNsense backup or use the documented independent router recovery path. Ansible does not attempt an automatic service rollback after a partial API apply.
