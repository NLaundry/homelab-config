# Manual Specbase verification sources

These procedures preserve the live-system evidence formerly embedded in legacy enforcement Markdown. They are intentionally not presented as automated checks.

## pools-import-on-boot-runtime

After a normal NAS boot, run `zpool status` on the NAS. Confirm that `smolBoy` and `mediaBin` are both imported without `-f` and report `ONLINE`. Record the date and observed pool state.

## operator-ssh-sudo-runtime

From the operator workstation, run `ssh -i ~/.ssh/id_ed25519 operator@10.10.10.11 'sudo whoami'`. Confirm key authentication succeeds without a login password and the command prints `root` without a sudo password prompt.

## test-store-kvm-runtime

From the operator workstation, run `nix build --store "ssh-ng://operator@10.10.10.11?ssh-key=$HOME/.ssh/id_ed25519&system-features=kvm%20nixos-test" --eval-store auto --no-link --rebuild .#checks.x86_64-linux.vm-harness-private-network -L`. Confirm the NixOS test starts both QEMU guests with forced acceleration, both guests reach `multi-user.target`, and the private-network assertions and peer pings pass. Record the date, store URI without secret material, and result.

**Attestation — 2026-08-17:** The command above completed successfully against `ssh-ng://operator@10.10.10.11` using derivation `/nix/store/rd700da8llqpp709ixasf5kcl5ba63qh-vm-test-run-harness-private-network.drv` and produced `/nix/store/3j7fshg6pzc7jx7j05wb4j4fv5nqcz36-vm-test-run-harness-private-network`. Because the runner sets `qemu.forceAccel = true`, both QEMU guests starting and reaching `multi-user.target` attest KVM availability. Each guest exposed only `testnet0` with its declared `192.168.250.0/24` address and route, had no default route or route to `10.10.10.1`, reached its peer by ping, and was terminated during successful cleanup.

## verification-credential-lifecycle

**Prerequisites:** the candidate configuration containing the locked `tester` Unix account and hidden verification share is active; the operator has key-based SSH and passwordless sudo; no tester run is in progress. Use `set +x` and `umask 077` throughout. The client file is `$HOME/.config/homelab/verification-smb.auth`; abort if it is a symlink or is not an operator-owned mode-`0600` regular file after installation.

**Provision:** generate a high-entropy password into a shell variable without placing it in a command argument or output. Deliver it twice over standard input to `ssh operator@10.10.10.11 'sudo smbpasswd -s -a tester'`. Create the client file through a mode-`0600` temporary file in an operator-only mode-`0700` directory with exactly `username = tester`, `password = ...`, and `domain = WORKGROUP`, then atomically rename it. Clear the shell variable. Verify `sudo pdbedit -L -u tester` succeeds and a new `smbclient --authentication-file=... //10.10.10.11/homelab-verification$ -c quit` session succeeds. Verify the file remains a non-symlink regular file owned by the operator with mode `0600` and no credential value appears in shell history, process listings, Nix derivations, or captured output.

**Rotate:** first run `sudo smbpasswd -d tester` to block new authentication, then `sudo smbcontrol smbd close-share 'homelab-verification$'` to terminate active share sessions. Generate and install a replacement secret through the same stdin-only and atomic-file procedure, run `sudo smbpasswd -e tester`, and reload Samba configuration. Confirm a saved previous authentication file cannot open a new session and the replacement file can. If replacement verification fails, disable the principal again, close active share sessions, restore the previous passdb secret from operator-held material through standard input, restore the previous client file atomically, re-enable, and verify before ending rollback.

**Retire:** disable the principal, close active verification-share sessions, inventory/recover residue using `live-verification-recovery`, preserve audit evidence, run `sudo smbpasswd -x tester`, remove the client authentication file, and verify both old and latest credentials fail. Passdb state under `/var/lib/samba` must survive ordinary NixOS deployments; repeat `pdbedit` and authentication verification after one deployment.

Record each provision, rotation, rollback, or retirement date; operator; passdb result; session-revocation result; sanitized client-file path and metadata; old/new authentication verdicts; and any residual run IDs. Never record a credential value.

**Attestation — 2026-08-17:** With the candidate generation active, the operator provisioned `tester` through `smbpasswd -s -a`, verified it through `pdbedit`, and installed `$HOME/.config/homelab/verification-smb.auth` as an operator-owned non-symlink regular file with mode `0600`. Rotation disabled the principal, closed verification-share sessions, replaced the passdb secret through standard input, atomically replaced the client file, and re-enabled the principal. The saved retired authentication file was rejected, the current file completed an authenticated create/read/rename/remove transaction, guest access was rejected, and no credential value was printed or passed as an argument. The full rollback drill then disabled the principal, closed sessions, preserved recent audit output, retired the passdb entry, activated a configuration without the verification module, and confirmed the Unix account, hidden share, and tmpfs mount were absent while both ordinary guest shares remained available. Restoring the module recreated the constrained boundary; the current secret was redelivered through standard input, and the eight-result default live suite (seven passing checks plus the intentional foundation skip) passed.

## live-verification-audit

**Prerequisites:** record a UTC start time immediately before one known verification run and retain its strict run ID. After the run, use operator SSH and query `journalctl -t smbd_audit --since <start> --until <bounded-end>` on the NAS, then restrict results to that exact run ID. Confirm records identify principal `tester`, the client address, share `homelab-verification$`, the namespace/file operation (`mkdirat`, create/open/write, rename when exercised, and `unlinkat`), and the run-scoped path. The tester must not be able to read or modify this output.

Record the date, bounded time window, run ID, expected and observed operation classes, sanitized matching records, and gaps. This procedure proves records retained in the queried journal window; it does not claim indefinite retention or delivery to an external log service.

**Attestation — 2026-08-17:** For capacity run `run-20260817T123136Z-073a2fe4d0966a85` in the bounded 16:30–16:32 NAS-local window, `journalctl -t smbd_audit` recorded principal `tester`, client `10.10.10.52`, share `homelab-verification$`, `mkdirat`, `renameat`, `create_file`, `pwrite`, and `unlinkat`, with every selected record containing the run ID. The byte limit rejected further allocation, an ordinary share remained listable, exact cleanup left the verification root empty, and a `tester`-identity journal query could not read the matching records. The journal remains local and subject to its configured retention.

## live-verification-recovery

**Prerequisites:** operate from an authenticated operator session and retain the exact run ID reported by a failed test. Disable new tester authentication with `sudo smbpasswd -d tester`, terminate active verification-share sessions with `sudo smbcontrol smbd close-share 'homelab-verification$'`, and preserve the bounded audit query before changing state.

Set the fixed root to `/var/lib/homelab-verification/smb/runs`. Reject a run ID unless it matches `^run-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{16}$`. Inventory only direct children with `find -P "$root" -mindepth 1 -maxdepth 1 -type d`; reject symlinks, missing targets, paths outside the canonical root, arbitrary paths, and prefix globs. For the one validated direct child, either rename it to an operator-owned quarantine name under the fixed parent or remove it with the following root-anchored sequence:

```bash
set -euo pipefail
root=/var/lib/homelab-verification/smb/runs
[[ $run_id =~ ^run-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{16}$ ]] || exit 2
target=$root/$run_id
sudo test -d "$target"
[[ ! -L $target && $(readlink -f -- "$target") == "$target" ]] || exit 2
sudo find -P "$target" -xdev -depth -delete
sidecar=$root/._$run_id
if sudo test -e "$sidecar" || sudo test -L "$sidecar"; then
  sudo test -f "$sidecar" && sudo test ! -L "$sidecar" || exit 2
  sudo rm -- "$sidecar"
fi
sudo test ! -e "$target" && sudo test ! -L "$target"
```

Verify that exact child is absent or quarantined and that sibling run namespaces and ordinary data are unchanged. Re-enable the tester with `sudo smbpasswd -e tester` only after verification. If recovery cannot be established, keep it disabled; rollback any quarantine rename to its exact original child only while sessions remain blocked, and report the exact residual path.

Record the date, operator, run ID, session revocation, bounded audit evidence, direct-child inventory, selected cleanup/quarantine command, final absence/residue, sibling-state check, and whether the principal was re-enabled.

**Attestation — 2026-08-17:** The operator disabled new tester authentication, closed verification-share sessions, and rejected the controlled outside-root target `../outside`. Recovery inventoried and validated five direct-child run IDs left by controlled cleanup failures, removed each exact no-follow one-filesystem namespace plus its exact AppleDouble sidecar, verified the verification root was empty, and re-enabled the tester. The recovered IDs were `run-20260817T121429Z-acd80856f9451c27`, `run-20260817T121700Z-0123456789abcdef`, `run-20260817T121817Z-4017d95d11131053`, `run-20260817T121843Z-15fbd1809fddec58`, and `run-20260817T121903Z-9be4ecb96f0abc92`. After explicit cleanup-failure injection was added, `tests/verify/profiles/smb-fixture-cleanup-failure.bats` returned an expected non-zero client status, preserved `controlled cleanup failure; residual run run-20260817T130142Z-d3d320e314efdd71`, and the same exact procedure recovered that run before re-enabling the tester.

## deploy-succeeds-runtime

From the operator workstation, run `make deploy` against the NAS. Confirm the build and activation complete successfully, then reconnect over SSH and confirm the activated generation is reachable. Record the generation and verification date.
