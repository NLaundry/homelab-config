# Estate registry evidence boundary

## Executed sources

- `nix run .#harness -- tests/estate/registry.bats` — six schema/export, production graph, diagnostic, diff, reconciliation, and check-derivation tests passed.
- `make test` — strict current-spec validation, all-system flake evaluation, 45 repository harness tests including the registry source, 14 tooling tests, Specbase instrument tests, and current Nix binding sources passed.
- The exact commands, implementation digest, timestamps, and exit results are retained in `estate-registry.log` and `make-test.log`.

## Evidence ladder

- **Declared model:** `lib.estateGraph` proves the desired nodes and relationships are normalized and internally valid.
- **Build/evaluation:** the Estate check derivation and reconciliation prove the registry and selected evaluated NAS facts do not contradict each other.
- **Virtual behavior:** unchanged existing VM evidence proves file-sharing behavior and isolation, not Estate placement.
- **Live behavior:** unchanged existing bounded probes show the current NAS serves SMB and exposes healthy selected pools at their recorded observation time.
- **Physical truth:** no Nix evaluation proves chassis location, disk attachment, cabling, continued health, or exclusive authority.

The typed registry strengthens declared-model and evaluated reconciliation evidence. It does not upgrade those physical limitations.
