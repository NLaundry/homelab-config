# North York backups and recovery

## Cadence, custody and status

The operator makes **weekly and pre-change** independent encrypted CA and router
copies, before relevant configuration, issuance/lifecycle, storage or identity
changes. Keep **four verified weekly copies plus the latest verified pre-change
copy**; do not remove the previous pre-change recovery point until its replacement
is verified and the change is accepted. Refresh after acceptance. Date and label
copies `weekly` or `pre-change`; retain their hashes and a small non-secret note
of versions, purpose, verification and prior service state. A failed attempt does
not replace a good copy. No new scheduler, service or helper framework is provided.

Keep at least one verified copy **outside the NAS failure domain**, for example
on the operator Mac and a separately stored encrypted recovery medium. Keep the
operator recovery age identity and native router-backup password independently
recoverable, not only on the NAS. Use an existing verified recipient and identity;
do not create a new recovery identity merely to run these instructions.

Fresh pre-change (2026-09-08) and post-migration (2026-09-09) router, CA and NAS
profile copies were independently encrypted and decrypt/hash verified outside
the NAS. CA capture restored its prior active state. Pre/post archive comparison
confirmed unchanged rollback JSON, authority and SOPS custody. These copies do
not prove weekly coverage or all router-plugin private-file recovery.

A real CA restore drill passed on 2026-09-09 from the 13:00Z encrypted copy: exact
active guest generation, read-only store, no NICs or host shares, and local scratch
on FileVault-protected APFS with encrypted swap. File content hashes, numeric
ownership and modes were checked before boot. Native SOPS, credential delivery,
CA/database startup, existing authority/operator identity and verified loopback
HTTPS passed. The clone powered off and scratch was removed; production stayed
healthy with root custody locked. The native Mac TCG fixture required PIC/PIT,
not KVM, and its root debug console existed only for the offline clone.

The encrypted NAS profile archive was checked against active bridge/port UUIDs
and association, without activating profiles. Fresh post-drill copies were
verified and the tested copy retained. This is not a full NAS/router restore or
interactive client acceptance. Section 7 of `simplify-north-york-stack` records
exact paths and remaining checks.

## CA and NAS profile capture

Run from the operator workstation during an approved window. Prerequisites:
Python 3, age and SSH locally; Bash, GNU tar, sudo and systemctl on the guest;
GNU tar and sudo on NAS. Confirm space and existing key-based sudo access first.
The known SSH path is `operator@10.10.10.11` as jump to
`operator@10.10.10.12`. Both host keys must already be independently verified.
A changed/missing key blocks backup; do not use `accept-new`, disable checking or
replace known_hosts based on an unverified scan.

CA archive contents are exactly the trees under `/var/lib/step-ca`,
`/var/lib/sops-nix` and `/var/lib/ssh`, preserving numeric ownership and private
modes. This includes the intermediate/database, commissioned marker, original
private rollback JSON, staged operator payload when present, SOPS ciphertext,
**guest age decryption identity and SSH host identity**. It excludes the offline
root private key. During capture, prohibit concurrent CA configuration/identity
changes. For NetworkManager profiles, prohibit concurrent profile edits; do not
stop networking to copy persistent files.

The following is a bounded inline operator procedure, not an installed script.
Set paths to your existing private files, not passwords. `RECIPIENTS` is a public
age recipients file for operator recovery; `IDENTITY` is that operator's existing
private age identity (not the guest identity). Use a fresh output directory on the
workstation, outside Git. Do not use shell tracing or record secret-bearing output.

```sh
export BACKUP_DIR="$HOME/.local/state/homelab-config/step-ca/backups/$(date -u +%Y%m%dT%H%M%SZ)-pre-change"
export RECIPIENTS=/absolute/path/to/verified-operator-recipients.txt
export IDENTITY=/absolute/path/to/operator-recovery-age-identity
```

Run this Python block locally with `python3`. Each transfer hashes plaintext in
1 MiB chunks while feeding age, then independently decrypts the result into the
same bounded hash calculation. **No plaintext tar archive is written.** Both the
remote tar/SSH exit and the encryption/decryption exits must succeed. All tool
stderr is suppressed because it is not needed for the safe summary; diagnose a
failure with scoped status/metadata, never by printing archived contents.

```python
import hashlib, os, pathlib, subprocess

os.umask(0o077)
base = pathlib.Path(os.environ['BACKUP_DIR']).expanduser()
base.mkdir(mode=0o700, parents=True, exist_ok=False)
recipient = os.environ['RECIPIENTS']
identity = os.environ['IDENTITY']
common = ['ssh', '-T', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=yes',
          '-o', 'ConnectTimeout=10', '-o', 'ServerAliveInterval=15',
          '-o', 'ServerAliveCountMax=3']
nas = common + ['operator@10.10.10.11']
guest = common + ['-o', 'ProxyCommand=ssh -o BatchMode=yes '
                  '-o StrictHostKeyChecking=yes -o ConnectTimeout=10 '
                  '-W %h:%p operator@10.10.10.11', 'operator@10.10.10.12']

# Record BEFORE stopping. Transitions are refused, not interpreted as inactive.
prior = subprocess.check_output(
    guest + ['sudo -n systemctl show -p ActiveState --value step-ca.service'],
    stderr=subprocess.DEVNULL, timeout=30).decode().strip()
if prior not in ('active', 'inactive', 'failed'):
    raise SystemExit('Refused: CA service is transitioning or state is unknown')
(base / 'ca.prior-state').write_text(prior + '\n')

remote = r'''set -eu
prior=PRIOR_STATE
current=$(systemctl show -p ActiveState --value step-ca.service)
[ "$current" = "$prior" ] || exit 20
cleanup() {
  rc=$?
  trap - EXIT HUP INT TERM
  if [ "$prior" = active ]; then
    if ! systemctl start step-ca.service >/dev/null 2>&1; then rc=21; fi
    if ! systemctl is-active --quiet step-ca.service; then rc=22; fi
  fi
  exit "$rc"
}
trap cleanup EXIT
trap 'exit 130' HUP INT TERM
systemctl stop step-ca.service >/dev/null 2>&1
[ "$(systemctl show -p ActiveState --value step-ca.service)" = inactive ]
# Keep stdout exclusively for the archive, including during cleanup.
tar --numeric-owner --acls --xattrs -C / -cf - \
  var/lib/step-ca var/lib/sops-nix var/lib/ssh
'''.replace('PRIOR_STATE', prior)


def capture(name, command, script=None):
    partial = base / (name + '.tar.age.partial')
    digest = hashlib.sha256()
    source = subprocess.Popen(command, stdin=subprocess.PIPE if script else subprocess.DEVNULL,
                              stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    if script:
        source.stdin.write(script.encode())
        source.stdin.close()
    try:
        with partial.open('xb') as output:
            sink = subprocess.Popen(['age', '-R', recipient], stdin=subprocess.PIPE,
                                    stdout=output, stderr=subprocess.DEVNULL)
            transfer_ok = True
            try:
                while chunk := source.stdout.read(1024 * 1024):
                    digest.update(chunk)
                    if transfer_ok:
                        try:
                            sink.stdin.write(chunk)
                        except (BrokenPipeError, OSError):
                            # Drain SSH so tar exits and its cleanup trap can restore
                            # prior state even when local encryption has failed.
                            transfer_ok = False
            finally:
                try:
                    sink.stdin.close()
                except (BrokenPipeError, OSError):
                    transfer_ok = False
            source_rc = source.wait()
            sink_rc = sink.wait()
        if not transfer_ok or source_rc != 0 or sink_rc != 0:
            raise RuntimeError('Capture/encryption/service restoration failed')
        verified = hashlib.sha256()
        decrypt = subprocess.Popen(['age', '-d', '-i', identity, str(partial)],
                                   stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        while chunk := decrypt.stdout.read(1024 * 1024):
            verified.update(chunk)
        if decrypt.wait() != 0 or verified.digest() != digest.digest():
            raise RuntimeError('Independent decrypt/hash verification failed')
        partial.rename(base / (name + '.tar.age'))
        (base / (name + '.tar.sha256')).write_text(digest.hexdigest() + '\n')
        print(name + ': encrypted capture and streaming hash verified')
    except Exception:
        # A .partial is never a verified backup. It contains ciphertext only.
        raise SystemExit(name + ': FAILED; preserve older backups; check prior service state')
    finally:
        source.stdout.close()
        # Normal transfer errors above drain and wait for remote cleanup. An
        # operator interrupt or lost host still requires independent recovery.

capture('ca', guest + ['sudo -n bash -s'], remote)
capture('nas-networkmanager', nas + [
    'sudo -n tar --numeric-owner --acls --xattrs -C / -cf - '
    'etc/NetworkManager/system-connections'])
```

After capture (including a failed attempt), compare `ca.prior-state` with a fresh
non-secret service status through the same verified jump. **Start the service
only if it was previously active.** A failed/inactive service is not permission
to start it. If previously active but now stopped, use the existing recovery
connection to run `sudo systemctl start step-ca.service`, then verify health as
in [step-ca](step-ca.md). A local interrupt, SSH loss, host failure or failed
service start can defeat any cleanup trap; the independently recorded prior
state and console recovery remain necessary. Do not report a backup successful
if state restoration failed, even if a ciphertext file exists.

The remote trap is armed before stopping and runs on tar/stop failure as well as
success. Unlike `/tmp/ny-ca-backup-before-acme.py`, it does **not** unconditionally
start the CA. That `/tmp` file is prior one-shot provenance only; do not copy it
as the operational procedure. The local code checks both sides of the stream,
not just age's exit status (age can encrypt a truncated tar successfully).

Copy the accepted ciphertext, hashes and prior-state note to independent recovery
custody. Re-run streaming decrypt/hash on that destination copy, not just a local
checksum of the source file. Retain NetworkManager backup updates whenever
profiles change and with weekly CA recovery sets. Their persistent files are not
recreated by a NixOS rebuild and may contain credentials; never publish them.

## Router backup: supported native UI

Use the existing **System → Configuration → Backups** native UI over the current
verified management profile; preserve hostname checking and the matching trust
anchor. This procedure uses native UI rather than guessing a `core/backup` API
request or broadening API privileges. The supported core/backup API is an
alternative only after its installed endpoint, export scope, authentication and
encryption behavior are reviewed. Do not print API configuration responses.

1. During an approved backup/download window, select the **complete** configuration
   export, not a partial section. Enable native password encryption. Enter the
   existing recovery password using a private prompt/password manager; never put
   it in a command argument, chat or Git. Record the installed router/plugin
   versions separately, without a full configuration response.
2. Download only the **encrypted** result to an operator-private directory outside
   the repository. A browser agent must use its explicitly approved download
   surface. Do not export raw XML to disk and promise to delete it later. If the
   UI cannot produce an encrypted full export, stop and review the supported API
   streaming path rather than silently accepting plaintext.
3. Wrap that already encrypted native export with independent operator age
   encryption. In Bash, with the paths above set and `DOWNLOAD` pointing to the
   encrypted native file, use a fresh name in private recovery custody:

   ```bash
   set -euo pipefail
   umask 077
   : "${DOWNLOAD:?Set the encrypted native download path}"
   : "${ROUTER_BACKUP:?Set a fresh absolute output path ending in .age}"
   test -s "$DOWNLOAD"
   test ! -e "$ROUTER_BACKUP"
   shasum -a 256 "$DOWNLOAD" | cut -d ' ' -f 1 > "$ROUTER_BACKUP.sha256"
   age -R "$RECIPIENTS" -o "$ROUTER_BACKUP" "$DOWNLOAD"
   actual=$(age -d -i "$IDENTITY" "$ROUTER_BACKUP" | shasum -a 256 | cut -d ' ' -f 1)
   expected=$(< "$ROUTER_BACKUP.sha256")
   test "$actual" = "$expected"
   printf '%s\n' 'Router age layer decrypt/hash verified'
   ```

   `pipefail` is required: a decryption failure must not pass as the hash of an
   empty/truncated stream. The hash covers the native encrypted export, not raw
   XML. These tools stream data; command substitution captures only the digest.
4. Independently decrypt/hash the external recovery copy too. Confirm the native
   layer/password by the isolated native restore procedure below; the outer age
   hash alone does not prove it is a usable OPNsense configuration. Keep the
   native encrypted download private or remove that redundant ciphertext after
   the independent copy is verified. Never keep an unencrypted XML intermediate.

A complete native config export may not cover every plugin's external runtime
file. Do not claim it proves ACME account/key recovery, NetBird identity recovery
or renewal persistence until an isolated native restore establishes those facts.
If the installed plugin requires additional supported backup coverage, that is a
recovery blocker to resolve in the live window, not permission to scrape raw
private directories into chat or recreate accounts.

## Verify a retained CA copy without extracting it

From Bash on the recovery workstation, with the chosen `CA_BACKUP` and
`CA_HASH` paths set, check the copy using the independent recovery identity:

```bash
set -euo pipefail
actual=$(age -d -i "$IDENTITY" "$CA_BACKUP" | shasum -a 256 | cut -d ' ' -f 1)
expected=$(< "$CA_HASH")
test "$actual" = "$expected"
printf '%s\n' 'CA recovery copy decrypt/hash verified'
```

Keep hashes in trusted custody with the backup. A matching hash detects accidental
truncation/difference; it is not proof of database integrity or fresh issuance
state. age authentication verifies ciphertext decryption, not operational recovery.

## Isolated restore and production recovery

### CA state and guest identities

1. Verify the selected ciphertext/hash first. Retain existing production state
   and record the recovery point's age: reverting Badger loses later issuance,
   revocation and account state. Obtain explicit approval for that loss before
   production rollback. Do not reset the database to fix a service error.
2. Prepare a disposable recovery host with encrypted scratch storage, **no VM
   network interfaces, no bridge/TAP attachment and no outbound network**. Use
   console access. Production keys must never reach a test network. Use dummy
   authorities for networked signing/failure tests. Do not boot the ordinary
   production guest definition unchanged for an isolated drill.
3. With the recovery VM stopped, attach a separate reviewed ext4 recovery image
   as `/mnt/ca-recovery-var` on that isolated host. Do not mount or overwrite the
   live image. The archive contains `var/lib/...`; restore that subtree into the
   image's root using GNU tar (the image itself is mounted as `/var` in the guest):

   ```bash
   set -euo pipefail
   age -d -i "$IDENTITY" "$CA_BACKUP" | sudo -n tar \
     --numeric-owner --same-owner --same-permissions --acls --xattrs \
     --strip-components=1 -xpf - -C /mnt/ca-recovery-var var/lib
   ```

   Run where GNU tar is available, not macOS BSD tar. A pipeline failure means a
   partial restore; keep the guest stopped and retry into clean isolated scratch
   state after diagnosis. No plaintext archive is saved, but restored files are
   plaintext runtime state and must remain in encrypted, access-restricted scratch.
4. Verify private modes and numeric owners against the selected guest generation.
   Restore `/var/lib/sops-nix/keys.txt` with root-only access and the original
   `/var/lib/ssh/ssh_host_ed25519_key`; do not generate replacements silently.
   The separately encrypted `guest-identity.age` is a recovery fallback for the
   guest age key, not a replacement for the database/full backup. Keep the
   operator recovery identity off the recovered guest.
5. Boot only the NIC-free recovery variant. Check the original root/intermediate
   fingerprints and commissioned record, actual SOPS credential delivery, guard,
   native database opening and loopback-only CA health. With separate enrollment
   approval, confirm the existing encrypted operator payload can be used without
   disclosing it. Inspect public results only. This can demonstrate local state
   recovery; it cannot establish production DNS/HTTP-01 or router renewal.
6. Shut down, detach and securely retire the encrypted scratch storage/key. Never
   connect the production-key drill guest to a test LAN. Record only non-secret
   outcomes and unresolved coverage; do not count a structural guard pass as a
   successful complete restore.

For approved production recovery, stop `microvm@step-ca.service` and verify QEMU
has exited before replacing/restoring its image. Confirm the exact mounted ZFS
dataset, ext4 label and `/smolBoy/services/step-ca/state.img` location. Preserve
image owner `microvm:kvm`, mode `0600`, and root:kvm `0710` parent directories.
Restore the verified state, select the paired service/config/template generation,
and start only after recovery checks and authorization. Never run `step ca init`
or unlock the root. Backups predating payload staging need the one-field staging
procedure in [step-ca](step-ca.md) before the new candidate can start.

Older NAS generations refer to the removed `/smolBoy/step-ca` path. Keep the
current storage path in a rollback build, or explicitly restore a stopped image
to a separately reviewed expected path; blind generation rollback is unsafe.
Missing mount/image/state must remain a refusal, not automatic image creation.

### Host networking

Restore `/etc/NetworkManager/system-connections` from its verified encrypted
archive on the isolated replacement host or with local-console access. Use the
same streaming age → GNU tar procedure, without `--strip-components=1`, into an
isolated root directory; install only the reviewed profile files on the target
as root, mode `0600`. Then `sudo nmcli connection reload` loads without activating.

Follow [NAS networking](nas-networking.md#host-reconstruction-and-recovery-ssh):
preserve `nasty-bridge`, `nasty-bridge-port` and the retained `Wired connection 1`
UUIDs, MAC/reservation `.11`, DHCP/IPv6 automatic addressing and explicit router
DNS `.1`. Verify the physical port/bridge before attaching the CA TAP. Activate
only with recovery access; do not activate bridge and fallback together. Verify
independent SSH, DNS, gateway and SMB before guest start. Do not replace
NetworkManager with another owner during recovery.

Temporary NAS password/root SSH remains a recovery exception. Retire it only in
a separately approved hardening change after named-operator key access and an
independent console/profile restore path have been demonstrated.

### Router

Use an isolated spare/VM with no production or test-network attachment and local
console. Before starting, verify that the installed version's supported local
restore path can import the encrypted backup without attaching a test NIC. If it
requires a networked UI and no safe local path is available, stop: this drill
remains blocked pending an approved isolation method. Do not invent a console
command, write `config.xml` by hand or connect production identities to a test LAN.

Decrypt the age layer to a private **still natively encrypted** export, then use
that supported native restore path with the recovery password entered through
its private prompt. Never write raw XML or decrypt the native layer into logs.
Review the installed version/plugin compatibility before restore. Keep every
restored interface disconnected: it contains production identities and addresses.

Verify preserved account/certificate references and actual required plugin state
without registration, issuance, peer enrollment or outbound connectivity. Mark
missing external plugin state as a failed recovery requirement, not success.
For real router recovery, retain console access and the previous valid certificate;
use native restore only in the approved outage window, then verify management
hostname/trust, DNS/DHCP, NetBird identity and existing ACME state. Do not wipe or
reboot production merely to prove a backup, automatically start ISC, or recreate
surviving accounts. Full renewal/served-TLS acceptance is still separate.
