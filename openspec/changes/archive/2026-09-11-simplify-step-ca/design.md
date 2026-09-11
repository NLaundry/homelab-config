## Context

The step-ca microVM configuration now lives under `hosts/nas/step-ca/` and is imported by `hosts/nas/guest-step-ca.nix`. The service currently declares a public configuration in `service.nix`, then `check-state.py` validates the commissioned state and assembles a private JWK payload into `/run/step-ca/ca.json` before starting step-ca. The persistent `/var` image contains the commissioned Badger database, root and intermediate certificates, and encrypted intermediate key.

See `proposal.md` for the motivation and `specs/configuration/step-ca/spec.md` for the required behavior.

## Goals / Non-Goals

**Goals:**

- Make the declared step-ca configuration the single runtime configuration source.
- Keep the commissioned state guard and protected intermediate-key checks before startup.
- Use ACME provisioners for current service issuance, with a general private-namespace path and a separate exact-name OPNsense path.
- Keep the implementation scoped to `hosts/nas/step-ca/`, its imported host module, and the existing read-only PKI verification surface.

**Non-Goals:**

- Recommissioning or migrating the Badger database.
- Changing the offline root, intermediate certificate, persistent state image, or OPNsense Ansible ownership.
- Adding SSH CA, OIDC/SSO, client-certificate, or host-SSH behavior.
- Adding a new runtime secret or a replacement direct-operator issuance path.

## Decisions

1. **Use the native module-generated configuration directly.** Remove the operator JWK provisioner, encrypted operator payload assembly, runtime JSON path, and related command-line modes. `check-state.py` will validate only the persistent commissioned state and cryptographic identity; it will not read or mutate generated configuration.

2. **Keep startup refusal separate from configuration generation.** The pre-start check continues to require the mounted `/var` filesystem, the trusted root identity, the commissioned intermediate identity, an encrypted intermediate key, and a usable Badger database. A missing or inconsistent commissioned state fails closed rather than initializing replacement state.

3. **Use two ACME provisioner boundaries.** The general service provisioner accepts exact DNS identifiers only within the private namespace and disables wildcard issuance. The OPNsense provisioner retains `opnsense.tpl`, which rejects any request other than the single approved DNS name and emits server-authentication usage only. The CA-wide two-name allowlist is removed because it would prevent new authorized service names.

4. **Keep the persistent state layout unchanged.** The existing `/smolBoy/services/step-ca/state.img` remains the only state volume. No state migration or authority reinitialization is part of this change; removal is limited to obsolete operator-payload files and code paths.

5. **Update verification without live mutation.** Existing read-only probes continue to check health, the commissioned intermediate, and the OPNsense certificate. Configuration-level checks may assert that the old operator assembly and CA-wide exact-name allowlist are absent; issuance tests must not create or replace live certificates without explicit authorization.

## Risks / Trade-offs

- [Risk] The general ACME namespace policy could be too broad if configured as a suffix match without exact-name validation. → Keep wildcard identifiers disabled and use the step-ca provisioner/policy mechanism that matches only DNS names under `laundrylab.internal`; validate the rendered configuration before activation.
- [Risk] Removing the operator provisioner can strand an existing administrative issuance workflow. → This change intentionally makes ACME the only current issuance interface; preserve the commissioned database and document direct operator issuance as out of scope rather than silently retaining a private payload path.
- [Risk] A malformed commissioned image could prevent startup. → Keep the existing fail-closed checks and test them locally with the current checker fixtures or focused Python tests.
- [Risk] The OPNsense template can be bypassed by another provisioner. → Keep the OPNsense ACME path separate and enforce its exact-name template; the general provisioner remains limited to the private namespace and rejects wildcards.

## Migration Plan

1. Build and inspect the NixOS configuration from the new `hosts/nas/step-ca/` paths.
2. Verify the generated step-ca configuration contains only the intended ACME provisioners and no operator encrypted payload assembly.
3. If the persistent state image still contains `secrets/operator-encrypted-key`, treat it as inert because no runtime path reads it; remove it only during an authorized state-maintenance window, not automatically during activation.
4. Run the checker and repository validation without changing the persistent state image.
5. Deploy only through the existing controlled activation workflow. On startup failure, restore the prior service configuration or revert the activation; do not initialize a new CA or replace the state image.
6. Run the existing read-only PKI probes after activation and confirm the CA endpoint, commissioned intermediate, and OPNsense certificate remain valid.
