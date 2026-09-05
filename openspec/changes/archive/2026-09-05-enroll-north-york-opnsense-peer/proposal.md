## Why

North York OPNsense must become a NetBird peer before it can later act as the Network router. Enroll the already-installed official plugin without enabling LAN routing or building unrelated router automation.

## What Changes

- Reuse the existing North York inventory, pinned OPNsense collection, SecretSpec credentials, and trusted TLS certificate.
- Add one North York playbook with a read-only compatibility/status preflight and separately gated preparation of bounded plugin settings.
- Configure only essential NetBird peer settings, with NetBird DNS, NetBird SSH, and route acceptance disabled.
- Require the operator to create one one-use setup key with an account authorized for setup-key management and connect through the official OPNsense UI.
- Keep the key out of Git, SOPS, OpenTofu state, command arguments, and logs; delete it from NetBird after the result is known.
- Add no interface assignment, firewall object, Network router assignment, access policy, DNS distribution, setup-key automation, or Scarborough configuration.

## Capabilities

### New Capabilities

- `configuration/opnsense-netbird`: North York OPNsense runs the official NetBird plugin as a bounded, unrouted peer.
- `lifecycle/netbird-enrollment`: enrollment is preflighted, idempotent, and consumes one ephemeral setup key.

### Modified Capabilities

- `governance/network-iac`: Ansible is the repository change path for managed OPNsense NetBird settings while OpenTofu remains the NetBird cloud-control path.

## Verification intent

| Covered truth | Planned proof |
|---|---|
| Plugin and API compatibility | The default playbook run reads version, settings, service, authentication, and status endpoints without mutation. |
| Enrollment remains bounded | Static syntax/structure checks reject interface, firewall, routing, DNS takeover, and setup-key persistence. |
| Setup key becomes unusable | The operator enters it only in the official OPNsense UI; the one-use key is deleted from NetBird after the result. |
| Enrollment is idempotent | A connected intended peer skips authentication and a repeated play reports no enrollment change. |
| Routing remains disabled | NetBird still reports no router on the North York Network after enrollment. |

## Impact

- Adds one bounded Ansible preflight/settings playbook, one small static check, and concise operating instructions.
- Later enrollment mutates only OPNsense NetBird plugin settings/service state and creates one NetBird peer identity.
- Makes no interface, firewall, routed-LAN, DNS-distribution, or Scarborough change.
