## 1. Declare the minimal baseline

- [x] 1.1 Extend `infra/netbird/` with the pinned North York Network, one peer-free resource group, and one LAN resource, and verify locked initialization and `tofu validate` succeed.
- [x] 1.2 Derive `10.10.10.0/24` from the unique North York LAN entry in `estate.yaml`, declare no second site, peer, router group, router, policy, DNS, or setup-key resource, and verify evaluation fails if that boundary is missing or changed.
- [x] 1.3 Document direct SecretSpec-scoped commands using native encryption, external `TF_DATA_DIR`, and an external local backend; verify Git ignores state and working data without adding a custom adapter.

## 2. Verify the declaration

- [x] 2.1 Add one `tests/iac/netbird-static-check` command that checks formatting, disposable locked initialization, validation, Git state exclusion, and exactly one peer-free resource group and absence of peer, router, policy, DNS, setup-key, and Scarborough declarations; verify it passes in the Nix shell.

## 3. Adopt the live objects

- [x] 3.1 Replace the draft `docs/operations/netbird-opentofu.md` with a concise inventory, import, plan, apply, re-import recovery, and stop procedure using no secret or state contents.
- [x] 3.2 Inventory the live NetBird account read-only; record the exact North York Network/resource-group/LAN-resource IDs and routing status, and stop on ambiguous ownership or unexpected active routing.
  - Result: the account contained no Networks and no exact resource-group match; there was no existing North York identity or routing state to import.
- [x] 3.3 Initialize encrypted external state, import exact matching North York Network, resource-group, and LAN-resource objects, and review one normal plan; apply only proven-missing baseline objects or harmless metadata normalization, with no replacement, deletion, routing, or unrelated-site change.
  - Result: no matching live objects existed. The reviewed plan created only Network `dae409qfadhs738pssj0`, resource group `dae409qfadhs738psskg`, and LAN resource `dae409qfadhs738pst30`; router, policy, and group-peer counts remained zero.
- [x] 3.4 Confirm a final SecretSpec-scoped plan reports no changes, then run `make check` and `openspec validate adopt-north-york-netbird-control-plane --strict` and record only sanitized summaries.
  - Result: final plan reported `0 to add, 0 to change, 0 to destroy`; the static check, Nix evaluation, strict OpenSpec validation, and Git operational-data exclusion passed.
