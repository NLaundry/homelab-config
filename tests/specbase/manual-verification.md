# Manual Specbase verification sources

These procedures preserve physical-system evidence that deterministic repository checks cannot establish honestly.

## pools-import-on-boot-runtime

After a normal NAS boot, run `zpool status` on the NAS. Confirm that `smolBoy` and `mediaBin` are both imported without `-f` and report `ONLINE`. Record the date and observed pool state.

## operator-ssh-sudo-runtime

From the operator workstation, run `ssh -i ~/.ssh/id_ed25519 operator@10.10.10.11 'sudo -n whoami'`. Confirm key authentication succeeds without a login password and the command prints `root` without a sudo password prompt.

## test-store-kvm-runtime

From the operator workstation, run `make test-vm`. Confirm the fixed aggregate NixOS test derivation starts its QEMU guests with forced acceleration, all guests reach their declared readiness conditions, private-network assertions pass, and the Samba client completes guest transactions. Record the date, sanitized store URI, and result.

**Attestation — 2026-08-17:** The private-network VM harness completed successfully against the NAS `ssh-ng` store with forced KVM acceleration. Both guests exposed only their declared private test interface and route, had no default route or physical-LAN route, reached their peer, and were terminated during successful cleanup.

## deploy-succeeds-runtime

From the operator workstation, run `make deploy` against the NAS. Confirm the build and activation complete successfully, then confirm the automatic default live verification succeeds. Record the generation and verification date.

## retired-verification-credential-cleanup

After the simplified generation is active and rollback confidence is established, the operator may delete obsolete local files `$HOME/.config/homelab/verification-smb.auth` and `$HOME/.config/homelab/verification-smb.retired.auth` without opening, printing, or adding their contents to the repository. The retired Samba passdb principal may be removed with `sudo smbpasswd -x tester`; absence is acceptable if it was already retired. This cleanup is not required to build or verify the repository.
