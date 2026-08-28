# Manual Specbase verification sources

These fenced procedures cover physical-system or transition facts that repository evaluation cannot establish. A procedure is not current evidence until its record identifies the tested revision/generation, environment, source persona, UTC time, freshness boundary, limitations, blast radius, and cleanup/result. Never record credentials or private key contents.

## pools-import-on-boot-runtime

### Procedure

1. Record the NAS hostname, active `/run/current-system` generation, `zpool status -x`, and the state of `mediaBin` and `smolBoy` before the event.
2. Perform one approved normal boot without `zpool import -f` or other repair action.
3. Record boot start/end times, elapsed time, active generation, failed units, and `zpool status mediaBin smolBoy` after boot.
4. Pass only when both pools were imported by the managed boot, report `ONLINE`, and forced root import was not used.

### Current evidence status

| Field | Value |
|---|---|
| Status | Deferred — no maintenance/reboot window was approved for this change. |
| Tested revision/generation | Not observed. |
| Environment/persona | Physical NAS; authorized operator. |
| Observation time/freshness | No current observation; a completed record is fresh for 30 days or until the NAS generation/storage topology changes. |
| Limitations | Evaluation proves selected import policy only; it does not prove boot import or physical pool health. |
| Blast radius | Host reboot and temporary service interruption; not executed. |
| Cleanup/rollback | Not applicable while deferred; a real record must include recovery and residue state. |

## operator-ssh-sudo-runtime

### Procedure

From the operator workstation, run a bounded, non-interactive probe:

```sh
timeout 60 ssh -o BatchMode=yes -o ConnectTimeout=5 \
  -i "$HOME/.ssh/id_ed25519" operator@10.10.10.11 \
  'printf "host=%s generation=%s\\n" "$(hostname)" "$(readlink -f /run/current-system)"; sudo -n whoami'
```

Pass only when approved-key authentication succeeds, the generation is reported, and the final line is `root` without a password prompt. Transport failure means access was not established; it is not an authorization result.

### Current evidence status

The current metadata is `tests/specbase/evidence/operator-access.json`; its digest-bound execution is retained with this change as `evidence/execution/operator-access-final.log` and authenticated by `evidence/final-execution-attestation.json`. It is point-in-time evidence, fresh for 24 hours or until SSH, account, sudo, key, network, or active-generation configuration changes. The probe is read-only, has no mutation blast radius, and requires no cleanup.

## test-store-kvm-runtime

### Procedure

From the operator workstation, run `make test-vm`. Record UTC start/end time, repository revision, sanitized store authority (omit key paths/query secrets), aggregate derivation, builder system/features, leaf results, network-boundary observations, and cleanup. Pass only when the fixed aggregate starts forced-KVM disposable guests, runtime private-network assertions pass, Samba transactions finish, and all guests terminate cleanly.

### Current evidence status

The current metadata is `tests/specbase/evidence/kvm-vm-suite.json`; its digest-bound execution is retained with this change as `evidence/execution/vm-tests-final-attested.log` and authenticated by `evidence/final-execution-attestation.json`. It is fresh for the tested implementation and builder identity. It proves disposable VM behavior, not the physical estate or live NAS services.

## deploy-succeeds-runtime

### Procedure

1. Record repository revision, selected flake target, build/activation host, SSH persona, privilege boundary, active generation, reachability, failed units, and pool state before deployment.
2. In an approved deployment window, run `make deploy` with the recorded inputs.
3. Record activation and verification events separately, UTC start/end times, elapsed time, resulting generation, reachability, failed units, pool state, exit status, rollback claim, and residue.
4. Pass only when the selected generation is active and independent post-deploy verification succeeds. A verification failure after activation remains a failure and must not imply rollback unless rollback was observed.

### Current evidence status

| Field | Value |
|---|---|
| Status | Deferred — persistent activation was not approved for this taxonomy-only change. |
| Tested revision/generation | Not observed by a transition. |
| Environment/persona | Physical NAS; authorized deployment operator. |
| Observation time/freshness | No current transition observation; a completed record is fresh for that exact revision/generation and 24 hours. |
| Limitations | Controlled adapters prove orchestration only; point-in-time health does not prove the preceding deployment. |
| Blast radius | Persistent NAS activation and possible service interruption; not executed. |
| Cleanup/rollback | Not applicable while deferred; a real record must identify rollback/residue explicitly. |

## retired-verification-credential-cleanup

After the simplified generation is active and rollback confidence is established, the operator may delete obsolete local files `$HOME/.config/homelab/verification-smb.auth` and `$HOME/.config/homelab/verification-smb.retired.auth` without opening, printing, or adding their contents to the repository. The retired Samba passdb principal may be removed with `sudo smbpasswd -x tester`; absence is acceptable if already retired. This cleanup is not required to build or verify the repository.
