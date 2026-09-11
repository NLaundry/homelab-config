# Manual PKI bootstrap and custody

**Initial custody verified on 2026-09-05.** The PKI was initialized once, recovery from Bitwarden was verified, and the dataset finished unmounted with its encryption key unavailable. No CA server was started. The creation commands below are historical bootstrap instructions, not instructions to initialize again. Run NAS commands on NASty, not on the MacBook. Use a private terminal without session recording or shell tracing. Never paste passwords or private keys into chat.

## Verified preparation

On 2026-09-05, `smolBoy` was healthy, its encryption feature was already enabled, and the target dataset/path was absent. All 22 existing filesystem/volume datasets were unencrypted. The effective shares were `/smolBoy/data` and `/mediaBin/data/media`, with wide links disabled; `/run` is tmpfs.

`boot.zfs.requestEncryptionCredentials = false` was deployed and both live pool-import scripts were checked for absence of key-loading/password-request commands. The existing deployment checks passed and both shares remained mounted. This is essential: `canmount=noauto` alone would not stop the previous boot password request. No pool upgrade or reboot is needed.

Smallstep 0.30.2 is installed permanently on NASty through `environment.systemPackages` in `hosts/nas/default.nix`, using the repository nixpkgs pin. It is also in the repository operator shell. The user selected this simpler installation after terminal pasting split the long temporary-shell command. Deployment and all three existing NAS checks passed; no PKI initialization occurred.

In your ordinary NAS SSH session, just run:

```sh
step version
```

No `nix shell` command is needed.

## Published trust anchor

Public certificate: [`certificates/laundrylab-root-ca.crt`](../../certificates/laundrylab-root-ca.crt).

- Subject: `LaundryLab Root CA`; ECDSA P-256.
- Root expires: 2036-09-02 19:27:23 UTC. The initial intermediate expires one second later; the usable chain lifetime is bounded by the root expiry.
- SHA-256 fingerprint: `C3:14:FA:8A:B3:4A:7C:E9:67:B9:BB:E5:28:78:69:43:F3:E7:F9:2E:C3:0E:57:B9:19:2A:C6:F0:BB:06:EB:D7`.

The operator confirmed the re-encrypted intermediate key matches its certificate. A restored encrypted root key from Bitwarden was decrypted privately and its public-key fingerprint matched the root certificate. The temporary recovered key was removed. The dataset was then locked, unlocked with its passphrase, read, and relocked; final status was `mounted=no`, `keystatus=unavailable`.

## 1. Before creation

Have ready:
- Bitwarden access that does not depend on this NAS or private CA.
- A unique dataset passphrase, root-key password, intermediate password and operator-provisioner password, saved privately.
- An independent encrypted recovery destination. Removable storage or a small encrypted PEM text copy in a free Bitwarden note is possible; no paid attachment feature is assumed. Same-vault passwords and keys mean that vault can recover the whole authority.
- A working `step` command from the pinned operator environment and sudo access on NASty.

Inspect without printing any secret:

```sh
sudo zpool status smolBoy
sudo zfs list -r smolBoy
sudo zfs get encryption,encryptionroot,keylocation,canmount,mountpoint,sharenfs,sharesmb smolBoy
```

Stop if the pool is unhealthy, the proposed dataset already exists unexpectedly, or `/smolBoy/pki-root` is occupied. Do not recreate the pool or place this below `/smolBoy/data`, which is SMB-shared.

## 2. Create only the approved dataset

After the command preview and your approval:

```sh
# Run this block only after approval; any existing destination is a stop.
if sudo zfs list -H smolBoy/pki-root >/dev/null 2>&1 || sudo test -e /smolBoy/pki-root; then
  printf 'Destination already exists; inspect it rather than recreate it.\n' >&2
  exit 1
fi
sudo zfs create -o encryption=aes-256-gcm -o keyformat=passphrase \
  -o keylocation=prompt -o canmount=noauto \
  -o mountpoint=/smolBoy/pki-root -o sharenfs=off -o sharesmb=off \
  smolBoy/pki-root
sudo zfs mount smolBoy/pki-root
sudo chmod 0700 /smolBoy/pki-root
sudo chown root:root /smolBoy/pki-root
```

ZFS prompts privately for its passphrase. If creation reports the dataset exists, stop; do not replace or destroy it. Confirm the effective properties and that no custom Samba/NFS share covers the path.

## 3. Initialize once

Use a root-only temporary file in NAS tmpfs for the **separate provisioner password**, entered without echo. First confirm `/run` is memory-backed and `/run/pki-init` does not already contain work from another session. This is a one-time private prompt, not a reusable secret wrapper:

```sh
sudo install -d -m 0700 /run/pki-init
sudo bash -c 'umask 077; read -r -s -p "Provisioner password: " p; printf "\\n" >&2; test -n "$p" || exit 1; printf "%s" "$p" > /run/pki-init/provisioner-password; unset p'
```

The password is not part of the command text or shell history. Do not enable shell tracing. Remove this file on success or failure; it is never part of the PKI backup.

The public options below are proposed defaults; confirm them before running:

```sh
# An existing init directory must be inspected, never overwritten.
if sudo test -e /smolBoy/pki-root/step; then
  printf 'PKI directory already exists; do not initialize again.\n' >&2
  exit 1
fi
sudo env STEPPATH=/smolBoy/pki-root/step "$(command -v step)" ca init \
  --name LaundryLab --dns ca.laundrylab.internal --address :443 \
  --provisioner laundrylab-admin \
  --provisioner-password-file /run/pki-init/provisioner-password
```

Enter the root-key password at the interactive encryption prompt. The command creates root, intermediate and configuration; **do not start step-ca here**. Do not run init again on the same authority.

Give the intermediate its own password before copying it out:

```sh
sudo "$(command -v step)" crypto change-pass \
  /smolBoy/pki-root/step/secrets/intermediate_ca_key
```

Enter its old initialization password and the new independent intermediate password when prompted. Remove the temporary provisioner-password file once initialization succeeds or fails with `sudo rm /run/pki-init/provisioner-password`, then `sudo rmdir /run/pki-init`. Do not use `--no-password`, `--insecure`, or a password argument.

## 4. Verify and back up once

Inspect both certificates and verify the intermediate chain:

```sh
sudo "$(command -v step)" certificate inspect /smolBoy/pki-root/step/certs/root_ca.crt
sudo "$(command -v step)" certificate inspect /smolBoy/pki-root/step/certs/intermediate_ca.crt
sudo "$(command -v step)" certificate verify \
  /smolBoy/pki-root/step/certs/intermediate_ca.crt \
  --roots /smolBoy/pki-root/step/certs/root_ca.crt
```

Confirm CA constraints and sensible validity. Compare the two **public-key** fingerprints below; they must match. The private-key command prompts privately and prints only a public fingerprint:

```sh
sudo "$(command -v step)" crypto key fingerprint /smolBoy/pki-root/step/certs/root_ca.crt
sudo "$(command -v step)" crypto key fingerprint /smolBoy/pki-root/step/secrets/root_ca_key
```

Repeat for `intermediate_ca.crt` and `intermediate_ca_key`. Use the same key-fingerprint operation on a restored encrypted key for the one recovery check; do not confuse a certificate fingerprint with its public-key fingerprint.

The selected recovery destination is free Bitwarden Secure Notes: separate notes for the encrypted root key, encrypted intermediate key, `ca.json`, root certificate and intermediate certificate. Paste complete file contents into the multiline **Notes** area, not custom fields. Keep configuration containing encrypted provisioner material private too. The initial custom-field copies lost PEM formatting; they were replaced from the unchanged originals before recovery succeeded.

Preserve PEM boundary lines, line breaks and the blank line after encryption headers. An encrypted EC key can legitimately have `BEGIN EC PRIVATE KEY` with `Proc-Type: 4,ENCRYPTED`; do not replace that header with a different PEM label.

For clipboard recovery, prepare the terminal transfer command first, then copy the note from Bitwarden and execute without copying another command over it. Never print key contents into chat or logs. Restore into a root-only temporary directory under `/run`, compare its public-key fingerprint using the private password prompt, and remove the temporary copy after success. Clear the Mac clipboard afterward. A same-pool snapshot is not independent recovery. Only the public root certificate and fingerprint are published in Git.

## 5. Lock and unlock

Close all files, then:

```sh
sudo zfs unmount smolBoy/pki-root
sudo zfs unload-key smolBoy/pki-root
sudo zfs get mounted,keystatus smolBoy/pki-root
```

Expected: unmounted and key unavailable. A busy unmount is a stop condition, not permission to force it.

For a later authorized operation:

```sh
sudo zfs load-key smolBoy/pki-root
sudo zfs mount smolBoy/pki-root
```

Read a public certificate, then relock. Complete this cycle once before acceptance. No NAS reboot or recurring drill is required. There is no encryption-password reset; a password cannot recover a failed disk without the backup.

## Stop or recover

On any failure, preserve the dataset and files, remove temporary password files, and lock custody when possible. Never regenerate the root as an automatic repair. Report only the failing step and non-secret status. A compromised root requires deliberate trust replacement, not just a new password.
