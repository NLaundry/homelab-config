# North York step-ca

## Status and boundaries

The existing intermediate CA is commissioned at `https://ca.laundrylab.internal`
(`10.10.10.12`, guest MAC `02:4c:4c:10:00:12`). Root custody remains locked:
`smolBoy/pki-root` is unmounted and its key unavailable. Never run `step ca init`,
recommission the database, generate a replacement guest identity, or unlock the
root for routine operation.

On 2026-09-09, the operator-authorized public-configuration migration was activated
and the VM explicitly restarted. Private payload staging, native startup and
NAS normal-trust health passed with the root locked. A subsequent explicit native
router renewal succeeded with existing ACME identities and automatic WebGUI
reload. Pre/post encrypted archives preserve the original rollback JSON,
authority and SOPS custody. A subsequent NIC-free restore from encrypted backup
passed native SOPS, credential delivery, CA/database startup and verified
loopback HTTPS with the same identities. The clone was removed. Operator
enrollment and client/off-LAN acceptance remain incomplete; see the change's tasks. See the [commissioning history](../../openspec/changes/deploy-north-york-step-ca/runbook.md)
for earlier evidence and incomplete acceptance.

## Configuration and persistent state

| Owner/path | Purpose |
|---|---|
| `guests/step-ca/default.nix` | Guest, persistent `/var`, DHCP and SSH identity |
| `guests/step-ca/service.nix` | One public CA declaration and native NixOS service |
| `guests/step-ca/opnsense.tpl` | Immutable exact-router signing restriction |
| `guests/step-ca/check-state.py` | External-state guard and one-field runtime assembly |
| `hosts/nas/step-ca-vm.nix` | Host mount/image guards and controlled VM lifecycle |
| `/etc/smallstep/ca.json` (guest) | Native module-generated public JSON |
| `/run/step-ca/ca.json` (guest) | Executed JSON; public JSON plus only operator `encryptedKey` |
| `/var/lib/step-ca/config/ca.json` (guest) | Existing private JSON, left untouched for rollback; current guard/service never reads it |

The published `certificates/laundrylab-operator-jwk.json` contains only the
existing operator's allowlisted public fields. Its identity was independently
compared with the running configuration and encrypted pre-ACME backup. The
existing `laundrylab-admin` provisioner **does have an encryptedKey**. This
candidate requires the string at
`/var/lib/step-ca/secrets/operator-encrypted-key`; missing/invalid material fails
startup, with no public-only fallback. Do not put it in Git, Nix values or build
inputs. The assembler accepts no private policy or template overrides. It writes
runtime JSON atomically, mode `0600`, inside a `0700` runtime directory.

The native NixOS module owns `LoadCredential` for `intermediate_password` and
supplies `$CREDENTIALS_DIRECTORY/intermediate_password`. Do not add a second
credential definition. Native credentials may appear as root:root mode `0440` because
of systemd's access mask. The guard accepts that only in the explicitly supplied,
trusted credential directory; private key/payload checks remain strict. Do not
chmod native credentials to work around a guard failure. SOPS decrypts `/var/lib/sops-nix/step-ca.yaml` using the
separate guest identity `/var/lib/sops-nix/keys.txt`; identity generation is off.
The persistent SSH host key is `/var/lib/ssh/ssh_host_ed25519_key`.

The image is `/smolBoy/services/step-ca/state.img` on the exact
`smolBoy/services/step-ca` ZFS dataset, mounted as guest `/var` (ext4 label
`step-ca-state`, 4 GiB). `autoCreate=false` prevents replacement on missing state.
Online storage is unencrypted and includes the decryption identity beside the
encrypted runtime secrets. Restrictive permissions are not disk encryption.
See [storage](service-vm-storage.md) and [independent backups](north-york-backups.md).

## Signing policy

- Effective listener: `0.0.0.0:443`, derived from native service address/port, not
  an independently edited `settings.address`. Server identity is
  `ca.laundrylab.internal`.
- Authority DNS allowlist: `ca.laundrylab.internal` and
  `opnsense.ny.laundrylab.internal`; no wildcards. Admin API and SSH CA are disabled.
- Existing operator enrollment through `laundrylab-admin` is unchanged. Keep
  its signing password in operator custody; the intermediate-password sealing
  helper is not an enrollment tool. Never put passwords or tokens in argv/logs.
- `opnsense` ACME provisioner: HTTP-01 only, directory
  `https://ca.laundrylab.internal/acme/opnsense/directory`. The template checks
  both normalized SANs and raw CSR SAN bytes: exactly one DNS SAN equal to the
  router name, and an empty or exactly matching CSR common name. No extra,
  duplicate, wildcard, case-variant or unsupported SANs; no template overrides.
- Output is server-only (`digitalSignature`, `serverAuth`), default/max lifetime
  `168h` (seven days), minimum `5m`. Native step-ca renewal/rekey is disabled for
  this provisioner; ACME renewal uses a fresh order and reruns signing restrictions.
  Template refusal occurs during finalization, not necessarily at order creation.

The router's explicit LAN HTTP-01 destination, daily eligibility, native daily
schedule and WebGUI deployment belong to [OPNsense ACME](opnsense-acme.md). Do not
force issuance during routine configuration reconciliation. The global two-name
allowlist alone is not the ACME restriction; the immutable template provides it.

## What startup proves

The guard checks the `/var` mount, required state, restrictive private-file
permissions, trusted root bytes, intermediate chain/key match, commissioned
intermediate identity, nonempty Badger `MANIFEST` and at least one nonempty SST
file. It checks the encrypted operator payload's bounded JWE structure, **not
its decryption or signing integrity**. MANIFEST/SST presence is likewise **not a
database-integrity check**. Native database opening, TLS health and authorized
operator enrollment are separate acceptance steps. Fixed refusal categories do
not justify dumping private JSON, credentials or unrestricted logs into chat.

## Approved migration/update window

These steps are instructions for a future authorized window, not actions already
performed. Obtain console/recovery access and current decrypt/hash-verified
[CA/router backups](north-york-backups.md) first. Keep the preceding generation
and original private JSON. Do not change root custody.

1. Review/build the exact candidate locally (`make check`, `make build`).
   Confirm its executed JSON, immutable template and native
   credential wiring. Confirm the host still uses the current image path.
2. Through the already verified NAS jump, stage only the encrypted provisioner
   field privately **inside the guest**, as root. Use the operator shell; do not
   print source JSON or the extracted string. The following bounded Python block
   runs on the guest with its available Python interpreter and `sudo -n`; it
   refuses an existing destination instead of overwriting it:

   ```python
   import json, os, pathlib, pwd
   source = pathlib.Path('/var/lib/step-ca/config/ca.json')
   assert source.stat().st_size <= 1024 * 1024
   cfg = json.loads(source.read_text())
   operators = [p for p in cfg['authority']['provisioners']
                if p.get('type') == 'JWK' and p.get('name') == 'laundrylab-admin']
   assert len(operators) == 1
   value = operators[0]['encryptedKey']
   assert isinstance(value, str) and 0 < len(value.encode()) <= 65536
   owner = pwd.getpwnam('step-ca')
   target = '/var/lib/step-ca/secrets/operator-encrypted-key'
   fd = os.open(target, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
   with os.fdopen(fd, 'w') as stream:
       os.fchown(stream.fileno(), owner.pw_uid, owner.pw_gid)
       os.fchmod(stream.fileno(), 0o600)
       stream.write(value + '\n')
       stream.flush()
       os.fsync(stream.fileno())
   print('Operator payload staged; source unchanged')
   ```

   Ensure the private parent directory is trusted and restrictive first. This
   extracts only `encryptedKey`; it does not independently verify the public JWK
   anew or prove payload decryption. If staging fails, inspect metadata privately;
   do not blindly rerun against a partial file. The candidate guard performs the
   structural check at startup. Verify owner `step-ca` and mode `0600` without
   reading the content. Leave `/var/lib/step-ca/config/ca.json` untouched.
3. Activate the reviewed NAS system closure through the normal approved host
   deployment procedure. `restartIfChanged=false` means host activation alone
   does **not** restart this guest. Confirm the managed VM's selected runner is
   the candidate before explicitly restarting on the NAS:

   ```sh
   sudo systemctl restart microvm@step-ca.service
   sudo systemctl is-active microvm@step-ca.service
   ```

   Restarting only the old guest's `step-ca.service` does not install a new guest
   system or make the new store template available. Do not patch the old private
   JSON to reference a store path absent from that generation.
4. On the guest, inspect only non-secret status and public certificates. Verify
   `step-ca.service` is active, existing intermediate fingerprint is unchanged,
   native database opening succeeds and existing account/state is preserved.
   From the repository root on a trusted client:

   ```sh
   curl --fail --show-error --cacert certificates/laundrylab-root-ca.crt \
     https://ca.laundrylab.internal/health
   curl --fail --show-error https://ca.laundrylab.internal/health
   ```

   The second command requires installed OS/client root trust. Neither check
   permits `-k`. Verify root custody remains unmounted/key unavailable on NAS.
   With separate issuance approval, use the existing interactive operator
   enrollment workflow to verify continuity and name restrictions. Test raw
   negative CSRs locally with dummy keys, not by exposing another live handler.
5. If acceptance fails, stop the CA, preserve state and select the preceding
   verified guest configuration against the same image. **Older NAS generations
   may use the removed `/smolBoy/step-ca` image path**: retain the current path in
   the rollback build rather than blindly switching to an old generation. Do not
   delete database/account state or initialize anything. Restore from backup only
   under the separate recovery procedure if state itself is damaged.

Refresh independent backups after acceptance. Real automatic router renewal,
served TLS replacement, Mac/iPhone normal trust, genuine off-LAN access and an
isolated restore remain separate obligations; a running guest is not their proof.
