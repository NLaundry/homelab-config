## Context

The existing root manages North York's Network, LAN resource, and peer-free resource group. OPNsense is connected; its plugin firewall integration is enabled, but LAN access and route acceptance are disabled. No reusable module, router group, or manually assigned interface exists.

## Goals / Non-Goals

Enable administrator-initiated North York LAN access using the existing peer and resource. Do not add multi-site abstractions, DNS, SSH, interface/firewall automation, backup infrastructure, rollback drills, or multiple overlapping test suites.

## Decisions

### Direct router assignment and explicit access

Resolve the unique connected OPNsense peer and use the provider's direct peer assignment rather than a router group. Enable masquerading to avoid return-route changes on LAN hosts; retain an explicit metric. Reuse the existing LAN destination group and add only one administrator source group and one one-way policy.

The operator approved `NY-Access` containing `iPhone-me` (`dae1nojl0ubs738pvj90`) and `Nathans-MacBook-Pro.local` (`dae59crl0ubs73beq440`) for full administrator-initiated access to `10.10.10.0/24`. `SC-Access` is the naming convention for a later Scarborough change; do not create it here. Live activation is authorized for this boundary; off-LAN verification still requires an appropriately located client. Inspect effective existing policies/routes as well as the proposed rule; conflicting grants must be resolved before activation.

### Let the plugin handle forwarding

Keep built-in firewall integration enabled. Enable LAN access and server-route acceptance; leave client-route acceptance, DNS, and NetBird SSH disabled. Check the installed client's inbound-block behavior before choosing that flag: allow forwarding without unnecessarily exposing OPNsense itself. Make Ansible update only intended changed settings and sync only when needed.

Do not assume a manually assigned `wt0` or persistent OPNsense pass rule is needed. If the supported plugin cannot forward without those changes, stop and explain the required scope rather than adding them silently.

### One connector check file

Replace `tests/iac/netbird-static-check` and `tests/ansible/opnsense-static-check` with `tests/verify/iac-connectors.bats`. Keep ordinary `tofu fmt`, locked init, `tofu validate`, and Ansible syntax commands in the development procedure; no recurring tests of HCL/YAML spelling, upstream tools, or repository layout.

The file provides independent, selectable checks:

- NetBird: an authenticated read of known account/Network metadata.
- OPNsense: an authenticated plugin status read with TLS verification.
- Routed service: a short-timeout TCP connection to an explicitly approved North York target/port; optionally ICMP for diagnosis.

Launch API checks through their matching existing SecretSpec scopes; the traffic probe needs neither credential. Print only safe pass/fail summaries. No plaintext credential files or environment dumps. Do not require local OPNsense access from the off-LAN traffic-test device, or both credential scopes on every invocation.

A LAN-local success is not evidence of NetBird routing. Run the routed check from outside North York, confirm the route uses NetBird, and ensure the service itself is listening. Missing test context is not a pass. If the selected device cannot run Bats, record an equivalent manual connection check without building a new mobile test harness.

### Proportionate acceptance and rollback

Review one normal plan, apply only approved objects/settings, check the selected routed service and local OPNsense management, and require final no-change reconciliation. Policy review retains the unauthorized-access boundary; without a separate peer test, report denial as reviewed configuration, not measured packet behavior.

On failed activation, disable the access policy and router assignment, then restore changed plugin routing settings. Keep the peer and baseline objects. No destructive rollback or mandatory disconnect/reconnect drill.

## Risks / Trade-offs

- A broad existing policy could bypass the intended source group: inspect effective access before activation.
- A local test could bypass NetBird: require off-LAN route evidence for routed acceptance.
- OPNsense remains a single routing failure point: local LAN communication does not depend on NetBird.
- Plugin forwarding may differ from assumptions: stop on incompatibility rather than inventing persistent firewall configuration.

## Migration Plan

1. Select administrator peers, permitted traffic, and an off-LAN test target with the operator.
2. Implement direct router/policy and minimal plugin-setting changes; validate with normal tool commands.
3. Consolidate network checks and replace the draft routing runbook with short usage and rollback instructions.
4. Obtain explicit activation approval, review the plan, apply, and run connector/traffic checks.
5. Confirm no-change reconciliation or withdraw activation on failure.
