## Why

The step-ca guest currently mixes a declarative public configuration with a separate commissioned configuration and a large runtime assembly guard. It also applies a CA-wide two-name DNS allowlist, preventing the certificate authority from serving the broader `laundrylab.internal` namespace. The service should be simplified around ACME-managed service certificates while preserving the commissioned CA state and leaving SSH CA as a separate future change.

## What Changes

- Remove the CA-wide exact DNS allowlist that limits issuance to `ca.laundrylab.internal` and `opnsense.ny.laundrylab.internal`.
- Keep wildcard issuance disabled by default.
- Preserve the narrowly scoped OPNsense ACME provisioner and its exact-name certificate template.
- Add the policy surface needed for general exact-name ACME service certificates.
- Remove the unused direct-operator JWK issuance path and its private encrypted-payload staging if ACME is the sole current issuance interface.
- Simplify startup and configuration handling so the commissioned Badger state and intermediate identity remain persistent and protected without a second runtime configuration assembly path.
- Preserve the existing CA endpoint identity, offline-root trust, intermediate key protection, persistent state image, and ACME renewal ownership on OPNsense.
- Leave SSH CA keys, SSH provisioners, OIDC/SSO, and SSH host configuration to a separate follow-up change.

## Capabilities

### New Capabilities

- `configuration/step-ca`: ACME-first private certificate authority behavior, namespace policy, persistent commissioned state, and service certificate issuance boundaries.

### Modified Capabilities

None.

## Impact

- Affects `hosts/nas/step-ca/`, including the NixOS service configuration, startup checks, and OPNsense certificate template.
- Affects the commissioned step-ca configuration and its persistent state migration procedure.
- Affects future ACME clients using `https://ca.laundrylab.internal`.
- Requires read-only acceptance checks for CA health, preserved intermediate identity, OPNsense certificate issuance, and rejection of wildcard names.
- Does not change the OPNsense Ansible implementation or add SSH CA functionality.
