# Network secret custody and delivery

## Current contract

Keep NetBird and OPNsense credentials in SOPS/age-encrypted
`secrets/network.yaml`. Private decryption identities stay outside Git and the
Nix store. SecretSpec 0.20+ delivers only the selected scope to a child process;
do not export/eval resolved secrets into the parent shell or create temporary
runtime credential files.

The initial secret foundation and authenticated reads were recorded as passing.
NetBird resources and the OPNsense peer are now managed by the current
[OpenTofu](netbird-opentofu.md), [routing](netbird-routing.md),
[DNS](opnsense-dns.md) and [ACME](opnsense-acme.md) procedures. Enrollment writes
are [retired](opnsense-netbird-enrollment.md). This guide does not authorize live
apply, permission changes, key creation or replacement of an existing identity.

## Prepare tools and the existing identity

From the repository root:

```sh
nix develop --no-update-lock-file
set +x
umask 077
export SOPS_AGE_KEY_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"
export SOPS_EDITOR='nvim -u NONE -i NONE -n --cmd "set noswapfile nobackup nowritebackup noundofile"'
secretspec --version
```

The editor flags disable configuration, history, swap, backup and undo files.
Use `vim` instead if necessary. SOPS temporarily decrypts for editing; keep that
workspace private and outside the repository. Never record the session, dump the
environment, enable tracing or put secrets in chat, screenshots, argv or history.

If the identity is missing on an existing installation, recover it below; do not
generate a replacement to solve a decryption failure. For a separately approved
first-time identity only:

```sh
install -d -m 700 "$(dirname "$SOPS_AGE_KEY_FILE")"
if test ! -e "$SOPS_AGE_KEY_FILE"; then
  age-keygen -o "$SOPS_AGE_KEY_FILE"
fi
chmod 600 "$SOPS_AGE_KEY_FILE"
age-keygen -y "$SOPS_AGE_KEY_FILE"
```

Only the printed public `age1...` recipient may enter `.sops.yaml`. Never display
or share the private `AGE-SECRET-KEY-...` line.

## Review policy and scope mappings

Root `.sops.yaml` selects `^secrets/network\.yaml$` and the approved public age
recipient(s). Preserve other valid rules; put this exact-path rule before broader
matches. A backup of the same identity needs no second recipient. Add a separate
recovery recipient only with approval and verified custody.

```sh
yq eval '.creation_rules' .sops.yaml
```

Root `secretspec.toml` uses
`sops://secrets/network.yaml?sops_config=.sops.yaml`, profile `north_york`, and
root-item JSON extraction from the existing nested YAML:

| Scope | Variable | Root item | JSON pointer |
| --- | --- | --- | --- |
| `opentofu` | `NB_PAT` | `netbird` | `/pat` |
| `opentofu` | `NB_MANAGEMENT_URL` | `netbird` | `/management_url` |
| `opentofu` | `TF_VAR_state_encryption_passphrase` | `opentofu` | `/state_encryption_passphrase` |
| `opnsense` | `OPNSENSE_URL` | `opnsense` | `/url` |
| `opnsense` | `OPNSENSE_API_KEY` | `opnsense` | `/api_key` |
| `opnsense` | `OPNSENSE_API_SECRET` | `opnsense` | `/api_secret` |

All six are required. Do not add plaintext defaults, fallback providers, prompts,
generation, `as_path` or a plaintext cache. Edit through SOPS, not SecretSpec
convention-addressed writes. Always select a nonempty scope: scopes narrow child
delivery, not the age identity's ability to decrypt the shared document.

Historical [policy validation](../../openspec/changes/archive/2026-09-05-establish-network-secret-operations/evidence/sops-policy-validation.md)
and [SecretSpec delivery validation](../../openspec/changes/archive/2026-09-05-establish-network-secret-operations/evidence/secretspec-validation.md)
record the original dummy-input checks. Recheck changed mappings/tool versions
with isolated dummy ciphertext, never production secrets. Those records are not
current live acceptance or a reason to recreate retired wrapper tests.

## Management transport

`ansible/group_vars/all/opnsense.yml` defines the two explicit verified profiles;
`ansible/tasks/opnsense-connection.yml` validates URL, credentials and trust file
before a request. Playbooks, the connector probe and DNS recovery share them.

| Profile | HTTPS hostname | Controller trust file |
| --- | --- | --- |
| `legacy` (explicit recovery) | `opnsense.localdomain` | `ansible/certificates/north-york-opnsense-web.pem` |
| `private` (current default) | `opnsense.ny.laundrylab.internal` | `certificates/laundrylab-root-ca.crt` |

Both select port 443 and retain `10.10.10.1` as the recovery connection address.
`OPNSENSE_URL` must be an HTTPS origin matching the selected hostname and port,
without a path, query, fragment or embedded credentials. The scoped URL and
shared default now use the private hostname after backup and served-certificate
verification. An explicit private check selects those same non-secret values:

```sh
ANSIBLE_CONFIG=ansible/ansible.cfg \
  secretspec --file secretspec.toml run --profile north_york --scope opnsense -- \
  env OPNSENSE_PROFILE=private OPNSENSE_URL=https://opnsense.ny.laundrylab.internal \
  ansible-playbook -i ansible/inventory.yml \
  ansible/playbooks/opnsense-credential-preflight.yml
```

Install the pinned collection as shown under **Check consumers** before invoking
Ansible. This default preflight checks local inputs only. Add
`-e opnsense_auth_check=true` for an explicit authenticated read and connected-peer
check. Do not confuse either result with served-certificate, browser, renewal or
off-LAN acceptance.

After the [private HTTPS procedure](opnsense-acme.md) verifies the served
certificate, alternate hostname and independent recovery, coordinate the shared
default and the SOPS `opnsense.url` value across all callers. No automatic fallback
occurs on TLS failure. Fixed-address DNS recovery retains hostname/SNI and its
matching trust anchor; a retained profile does not make the router serve an old
certificate. Do not use bare-IP HTTPS or disable verification. The retained legacy
certificate's recorded expiry is 28 October 2026; verify replacements before use.

## Review permissions without changing grants

The original OPNsense discovery recorded `netbird-automation` / `svc-admin` with
four approved subsystem privileges: **VPN: NetBird**, **Interfaces: Assign network
ports**, **Firewall: Alias: Edit**, and **Firewall: Rules [new]**. This is historical
baseline evidence, not today's complete expected grant set; later DNS and ACME
work has separate approvals. See the archived
[OPNsense inspection](../../openspec/changes/archive/2026-09-05-establish-network-secret-operations/evidence/opnsense-inspection.md)
and the [current ACME permission boundary](opnsense-acme.md#required-privileges).
Source revisions are research references, not proof of installed compatibility.

Review the actual account/group in **System → Access → Users / Groups** against
the approved operations before use. Retain the service account's scrambled
password, no shell/SSH access and no full-admin membership. These API privileges
are subsystem-wide, not per managed object. Stop on a denied required endpoint;
never silently grant more access, remove write restrictions or recreate the user.
Routine checks do not require old ISC migration or firmware/backup permissions.

NetBird's `Config Automation` service user has the **Network Admin** role. Its
recorded `Infra Token` expires on 5 September 2027 and has Bitwarden custody.
Verify current validity before use. The role covers account-wide Network,
resource, group, router-assignment, policy and DNS management, not peer mutation
or setup-key creation. An OpenTofu plan limits intended changes, not token powers.
Do not widen this role for enrollment.

## Edit or rotate credentials

Use the existing encrypted file:

```sh
sops secrets/network.yaml
```

For approved creation/rotation, transfer values directly between the native
credential UI/password manager and the private SOPS editor. OPNsense API key
creation is under **System → Access → Users → svc-admin → API keys**. Keep its
one-time download private and outside the repository, then remove it after
transfer. Use the existing NetBird service user's approved token. Never store a
peer setup key in this file or OpenTofu state.

Keep the fields in the scope table unchanged. NetBird Cloud uses
`https://api.netbird.io`; confirm any different deployment. The state-encryption
passphrase must be a unique password-manager value of at least 32 characters.
Do not replace a passphrase needed to decrypt existing state as if it were an API
token; preserve encrypted state and follow a separately reviewed migration.

Save and inspect only ciphertext and public metadata. Prove replacement API
credentials with scoped read-only authentication before revoking predecessors.
Record dates, public fingerprints, non-secret IDs, approved privileges and results,
never decrypted values or raw credential-bearing responses.

## Check consumers

Install the pinned collection before Ansible commands:

```sh
ansible-galaxy collection install -r ansible/requirements.yml -p .ansible/collections
ANSIBLE_CONFIG=ansible/ansible.cfg \
  secretspec --file secretspec.toml run --profile north_york --scope opnsense -- \
  ansible-playbook -i ansible/inventory.yml \
  ansible/playbooks/opnsense-credential-preflight.yml
```

For separately selected live authenticated reads:

```sh
secretspec --file secretspec.toml run --profile north_york --scope opentofu -- \
  bats --filter 'NetBird API connection' tests/verify/iac-connectors.bats

ANSIBLE_CONFIG=ansible/ansible.cfg OPNSENSE_VERIFY=1 \
  secretspec --file secretspec.toml run --profile north_york --scope opnsense -- \
  bats --filter 'OPNsense API connection' tests/verify/iac-connectors.bats
```

The OPNsense connector invokes the shared preflight with explicit inventory and
requires management connectivity as well as API access. Selected missing inputs
fail; a skipped test is not a pass. Apply no configuration to diagnose a failed
read. Keep full model responses and credential-bearing output suppressed.

`infra/netbird/` now owns seven resources, not an empty bootstrap root. It uses
native encrypted external state/plans and an ephemeral sensitive passphrase.
Initialize, plan, apply or recover only through [OpenTofu operations](netbird-opentofu.md),
with its existing external backend; never overwrite surviving state.

## Recover custody and revoke access

- Keep `keys.txt` as an encrypted Bitwarden attachment, not in notes. Test the
  Bitwarden account's own recovery independently of this workstation. Download
  verification/recovery copies only into a mode-`0700` directory outside Git.
- Use `age-keygen -y` on a retrieved copy and compare its public recipient with
  `.sops.yaml`. Stop if parsing or identity differs; do not display private data.
  Install a required recovery copy at the conventional SOPS path with directory
  mode `0700` and file mode `0600`. Otherwise remove it and lock Bitwarden.
- For approved age rotation, add and verify the replacement public recipient,
  run `sops updatekeys secrets/network.yaml`, and prove independent recovery
  before removing an old recipient. An exposed key also requires rotating the
  underlying credentials: recipient changes cannot protect old ciphertext.
- Revoke PATs in NetBird and API keys in OPNsense. Deleting local ciphertext or
  rewriting Git history does not revoke remote access. Preserve access until an
  approved replacement passes unless immediate revocation is required for compromise.

## Sources

- [Archived secret-foundation change](../../openspec/changes/archive/2026-09-05-establish-network-secret-operations/).
- [SecretSpec SOPS provider](https://secretspec.dev/providers/sops/), [configuration](https://secretspec.dev/reference/configuration/) and [scopes](https://secretspec.dev/concepts/scopes/).
- [SOPS](https://getsops.io/docs/) and [age](https://age-encryption.org/).
- [NetBird API access](https://docs.netbird.io/how-to/access-netbird-public-api).
- [OPNsense privileges](https://docs.opnsense.org/manual/users.html) and [API keys](https://docs.opnsense.org/development/how-tos/api.html#creating-keys).
