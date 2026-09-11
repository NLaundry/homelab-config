# OPNsense native ACME

## Ownership

Ansible owns the existing selected ACME account, LAN HTTP-01 challenge, WebGUI
reload automation, certificate definition, plugin enablement and native renewal
schedule. Native ACME keeps all account/key state and performs issuance and
renewal. Ansible never signs, registers, deletes or recreates objects during
reconciliation. The CA remains Nix-managed with external private state.

**Current verification (2026-09-09):** authorized adoption and repeat matched
configuration/schedule with zero changes through verified private-name TLS.
After the controlled CA restart, one separate explicit native renewal succeeded:
served serial initially became `8EA6895566A626C24EF3E1D58AA8C589` following
automatic WebGUI reload. After approved failure checks, a recovery renewal served
`4EA1D419A4C9A80795326EBCE47D320A`, expiring 2026-09-16T12:58:55Z. Native UUIDs, Trust ref
and account-key fingerprint were preserved. Fresh exact-name/chain TLS and
macOS native-curl normal trust passed; refreshed encrypted backups were verified.
Approved CA-unavailable and HTTP-01-blocked checks returned fresh failures while
preserving the valid certificate, then restored health and normal HTTP behavior
within 108 and 71 seconds respectively. Direct router PF-anchor/token-file inspection
remains unavailable through current APIs; behavioral recovery is not a claim of
that inspection. Ordinary-browser and off-LAN acceptance remain open. Routine Ansible reconciliation did not request this renewal.

## Required privileges

Grant through **System → Access → Users / Groups → Assigned privileges**:

| Privilege | ID | Scope |
| --- | --- | --- |
| Services: ACME Client | `page-services-acmeclient` | Entire ACME API, including issuance and automations |
| System: Settings: Cron | `page-system-cron` | Entire Cron API; used to inspect and reconcile the exact native job |

These are not per-certificate permissions. The role does not grant privileges and
stops on a denied API. Do not grant All pages or generic service administration.
Do not silently remove an account's Deny config write restriction.

Optional bootstrap privileges are **System: Trust: Authorities**
(`page-system-camanager`) for public-root import, and **System: Firmware**
(`page-system-firmware-manualupdate`) for plugin installation/firmware inspection.
They are not routine prerequisites. Native ACME internally imports its issued
certificate and invokes its linked WebGUI restart without separate Trust or
Status: Services grants. The controller's trust file needs no appliance privilege.

The detailed source-derived endpoint map and module limitations are in
[the adopted design](../../openspec/changes/simplify-north-york-stack/permissions.md).
Update that link when the change is archived; the privilege summary here remains
the operating reference.

## Prepare the local tools

Run from the repository root:

```sh
nix develop
ansible-galaxy collection install -r ansible/requirements.yml -p .ansible/collections
export ANSIBLE_CONFIG="$PWD/ansible/ansible.cfg"
export SOPS_AGE_KEY_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"
```

Use the existing operator identity. Never generate or overwrite an identity to
resolve a decryption failure. On this Mac, explicitly selecting the documented
identity path is necessary for SecretSpec/SOPS decryption.

## Compare without writes

The routine default and encrypted scoped URL now both use the private hostname.
The explicit values below select that same verified profile; they are not an
insecure fallback. The legacy profile remains available only with its matching
certificate selected for recovery:

```sh
secretspec run --profile north_york --scope opnsense -- \
  env OPNSENSE_PROFILE=private OPNSENSE_URL=https://opnsense.ny.laundrylab.internal \
  ansible-playbook -i ansible/inventory.yml ansible/playbooks/opnsense-acme.yml
```

Expected: zero changed tasks, counts for configuration/schedule differences and a
bounded challenge-service status. Missing, duplicate or incompatible identities
stop adoption before writes. The role never selects the first duplicate or makes
a new account/job as a repair. Full model responses remain hidden because they
can contain private account and automation data.

## Apply approved configuration

1. Verify installed plugin compatibility and private-root trust, capture a fresh
   independently encrypted router backup and retain management recovery.
2. Stop competing UI/configuration edits during adoption. Native APIs do not
   provide a transaction spanning the identity read and update.
3. Run the comparison command with `-e apply_acme=true` appended. Only changed
   owned fields are written; existing UUIDs, account registration, Trust reference
   and unowned settings are preserved.
4. Repeat and require no changes. Verify saved state separately from served TLS.
   The native Cron reconfigure API acknowledges the restart request but has no
   service-status endpoint in this version. That acknowledgement is not proof
   that the scheduled job ran; real renewal remains required acceptance.

The native renewal job keeps its origin, command, parameters and UUID. The role
repairs an empty/stale link only to one existing compatible job. It does not
create a second generic cron job. Keep the seven-day CA lifetime, daily renewal
eligibility and enabled daily native schedule together.

## Recover a failed apply

A save can succeed before challenge-service or cron application fails. Inspect the
failure, then repeat the comparison/apply command with both:

```text
-e apply_acme=true -e reapply_acme=true
```

Reapply regenerates the native service/schedule configuration even if saved fields
already match. It does not issue a certificate or restart the WebGUI. A failed
service check remains a failure; do not bypass TLS or grant additional permissions
to make a failed run green.

## Keep the legacy GUI boundary explicit

**System → Settings → Administration → Web GUI** remains the operator step for
initial SSL Certificate selection and Alternate Hostnames. Select the issued
certificate and permit `opnsense.ny.laundrylab.internal`, keeping DNS-rebind,
referrer and TLS checks enabled. Its Trust refid is not the ACME/API UUID.

No supported management API was found for those legacy fields. Do not post a
partial legacy form, write config.xml or run remote PHP. The selected native
`configd_restart_gui` automation reloads the chosen certificate; it does not
choose one or add a hostname. Retain the old certificate for explicit recovery.

## Install client trust and check HTTPS

Compare the public root's SHA-256 fingerprint before importing it:

```sh
openssl x509 -in certificates/laundrylab-root-ca.crt -noout -fingerprint -sha256
```

Expected DER SHA-256:
`c314fa8ab34a7ce967b9bbe528786943f3e7f92ec30e57b9192ac6f0bb06ebd7`.
NixOS uses `security.pki.certificateFiles` with that public certificate only.
On the approved Mac, the following operator-authorized import already succeeded;
repeat only when restoring or deliberately changing client trust:

```sh
security add-trusted-cert -r trustRoot -p ssl \
  -k "$HOME/Library/Keychains/login.keychain-db" certificates/laundrylab-root-ca.crt
```

On the approved iPhone, install the same verified public certificate profile and
explicitly enable its SSL trust under Settings → General → About → Certificate
Trust Settings. Client trust changes require operator approval. Import success
or `step ca bootstrap` alone is not ordinary-browser acceptance.

Run the independent normal-trust CLI check from the intended client:

```sh
HTTPS_VERIFY=1 HTTPS_URL=https://opnsense.ny.laundrylab.internal/ \
  nix develop --command bats tests/verify/naming-trust.bats
```

On this Mac, Nix curl's OpenSSL trust store did not contain the private root
(error60), while native macOS curl passed. To explicitly test the native client's
normal trust without a CA override (HTTPS only):

```sh
DNS_VERIFY=0 HTTPS_VERIFY=1 HTTPS_URL=https://opnsense.ny.laundrylab.internal/ \
  nix develop --command bash -c 'PATH=/usr/bin:$PATH exec bats tests/verify/naming-trust.bats'
```

Run the separately selected DNS probes with the default Nix tool path: this
Mac's older `/usr/bin/dig` rejects `-r`. For a combined run, put only a symlink to
native curl first on PATH, leaving Nix dig selected; do not replace the whole
suite's tools with `/usr/bin`.

The trailing slash is intentional. This probe rejects redirects and HTTP/TLS
errors and ignores curlrc. It uses the selected curl build's normal trust; it does
not prove every curl build or ordinary-browser acceptance. DNS outcomes are separately opted in. Also open the exact
router URL in the ordinary Mac/iPhone browser without certificate overrides.

## Verify lifecycle separately

- Observe a real native renewal and a changed served serial/expiry after automatic
  reload. A no-op renewal or saved cron does not pass.
- For an explicitly approved forced lifecycle check, use the native certificate
  grid's issuance/renewal action, then verify completion and fresh served TLS.
  Do not blindly retry asynchronous `/sign` requests or the defective standalone
  `/automation` and `/import` response paths.
- Confirm ordinary Mac/iPhone browser trust and genuine off-LAN private/public DNS
  and HTTPS. Explicit-root curl is not browser trust acceptance.
- Preserve the valid certificate through temporary CA/challenge failure; test
  cleanup in isolation or an approved bounded window, never by wiping router state.
- Refresh independently encrypted router and CA recovery backups after acceptance.
