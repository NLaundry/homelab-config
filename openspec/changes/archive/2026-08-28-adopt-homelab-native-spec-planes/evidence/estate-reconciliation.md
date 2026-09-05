# NAS Estate reconciliation

## Declared placement review

- **Revision:** `32a5772200a82509db25a27647a28ee7ae3590b3` plus the uncommitted plane-migration worktree.
- **Reviewed:** 2026-08-28 UTC.
- **Reviewer/persona:** repository implementation review.
- **Declared role:** `nixosConfigurations.nas` composes `hosts/nas/default.nix`.
- **Workload declaration:** the NAS role imports `hosts/nas/samba.nix`, which owns the file-sharing service realization.
- **State declaration:** the NAS role imports `hosts/nas/zfs.nix`; evaluated `boot.zfs.extraPools` is exactly `mediaBin` and `smolBoy`.
- **Result:** repository declarations are consistent with assigning the file-sharing workload and authoritative pool responsibility to the NAS role.

## Read-only runtime reconciliation

On 2026-08-28 at 19:26:58Z, a bounded approved-key SSH probe observed:

- host `NASty`,
- active generation `/nix/store/q5zcyid8f0iv10cf2k23bbh8q9vr4qlj-nixos-system-NASty-26.05.20260804.04607e1`,
- active `samba-smbd.service`,
- `mediaBin` and `smolBoy` both `ONLINE`,
- `zpool status -x`: all pools healthy.

The sanitized command/result is retained in `evidence/execution/estate-reconciliation.log`.

## Independent reconciliation boundary

A source/module review, evaluated option set, and point-in-time runtime observation establish declared topology and realization alignment. They do **not** prove:

- which physical chassis currently serves traffic,
- physical disk attachment or exclusive ownership,
- that the observed workload and pools remain healthy after the observation,
- absence of an undeclared second authority.

The runtime observation remains point-in-time evidence and cannot establish cabling or exclusive physical authority. These limitations remain explicit until `introduce-typed-estate-registry` provides the declared graph and bounded reconciliation contract.

## Freshness

This review is current for the reviewed revision and becomes stale when host composition, Samba placement, ZFS pool declarations, hardware placement, or active Estate policy changes.
