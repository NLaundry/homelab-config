## 1. Simplify the step-ca runtime configuration

- [x] 1.1 Update `hosts/nas/step-ca/service.nix` to remove the direct JWK provisioner, CA-wide two-name DNS allowlist, runtime configuration path, and operator payload assembly while retaining the commissioned root/intermediate paths, Badger database, ACME provisioners, wildcard rejection, and OPNsense template; verify the Nix expression evaluates successfully.
- [x] 1.2 Add the general ACME service provisioner policy for exact DNS names under `laundrylab.internal`, keep the OPNsense provisioner separately constrained by `hosts/nas/step-ca/opnsense.tpl`, and verify the rendered configuration exposes no wildcard or out-of-namespace issuance path.

## 2. Keep commissioned state fail-closed

- [x] 2.1 Simplify `hosts/nas/step-ca/check-state.py` so it validates the mounted commissioned state, root identity, encrypted intermediate key, intermediate identity, and Badger database without reading or assembling a public configuration or operator encrypted payload; verify focused checker failure/success cases locally.
- [x] 2.2 Update the service pre-start and `ExecStart` wiring to invoke the simplified checker and start the native step-ca configuration directly with the intermediate password credential; verify no `runtimeConfig`, `payload-mode`, `public-config`, or `operator-encrypted-key` references remain in active code.

## 3. Verify and document the migration boundary

- [x] 3.1 Remove the unused repository-side operator JWK input if no remaining code references it, and record that any obsolete persistent payload is inert and must not be used; verify repository references and secret declarations remain valid.
- [x] 3.2 Run repository validation and focused tests for the step-ca checker and configuration, then update this task list only after the implementation and read-only verification checks pass.
