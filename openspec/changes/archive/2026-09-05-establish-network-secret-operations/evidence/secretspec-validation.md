# One-time SecretSpec verification

Date: 2026-09-05

- SecretSpec 0.20.0 is supplied by the separately locked `secretTools` input.
  The existing host nixpkgs lock entry is unchanged.
- `nix develop --no-update-lock-file --command secretspec --version`: PASS on
  aarch64-darwin, reporting `secretspec 0.20.0`.
- One-time dummy integration: PASS. All six nested fields in the repository
  manifest mapped to their intended child variables under `north_york`.
  The `opentofu` and `opnsense` scopes excluded the opposite family's variables.
- The verification used a copied manifest, a generated dummy age identity, and
  temporary dummy ciphertext. It did not use production identities or credentials.
- The temporary six-case Bats harness was run with
  `nix develop --no-update-lock-file --command bats tests/secrets/contracts.bats`.
  It passed 6/6, including initial additional upstream-behavior checks. The harness
  was then removed by user decision: retain this result, not a recurring test of
  SecretSpec or SOPS. Recheck mappings after a manifest or SecretSpec change.
- `make check`: PASS; evaluates both aarch64-darwin and x86_64-linux without builds.
  Linux execution was not tested on this Darwin operator machine.
- `openspec validate establish-network-secret-operations --strict`: PASS.
- `git diff --check`: PASS.

## Local consumer wiring

- `infra/netbird/` pins `netbirdio/netbird` 0.0.10, reads its two standard
  `NB_*` variables, and requires native AES-GCM encryption for state and plans
  from a sensitive, ephemeral input. The lock contains Darwin ARM64 and Linux
  AMD64 checksums. Isolated `tofu init -backend=false` and `tofu validate`: PASS.
- `ansible/requirements.yml` pins the OPNsense collection to immutable commit
  `7de29c528f9326b10ba74184e64a214d961c4811`. The local credential preflight
  reads the three `OPNSENSE_*` variables, uses direct module defaults, HTTPS
  verification, `no_log`, and pipelining; it creates no credential file.
- A final one-time check launched both consumers through their matching
  SecretSpec scopes with temporary dummy ciphertext: PASS. It contacted neither
  NetBird nor OPNsense and retained no fixture.

This proves local credential and state-encryption configuration. It does not
prove remote authentication, create OpenTofu state, or implement the later
network resources and OPNsense enrollment operations.
