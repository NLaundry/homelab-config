# Prepare network secret custody

## What

Keep NetBird and OPNsense credentials in `secrets/network.yaml`, encrypted with
SOPS and age. Keep private decryption identities outside Git and the Nix store. Use SecretSpec
0.20+ with its SOPS provider and root `secretspec.toml` for scoped environment
delivery, not custom adapters or temporary runtime credential files.

## Why

Automation needs credentials. It must not leave plaintext files, logs, or shared
shell variables behind. A separate recovery copy prevents permanent loss of access.

## Before you start

The shared secret foundation is complete: operator custody, root `.sops.yaml`,
SecretSpec 0.20.0, encrypted `secrets/network.yaml`, local OpenTofu and Ansible
credential wiring, and bounded read-only authentication are recorded as passing.

Full NetBird resource management and OPNsense enrollment remain later changes.
This runbook does not authorize a live apply, setup-key creation, or enrollment.

You need local OPNsense access, NetBird administrator access, and an encrypted
recovery location independent of this workstation. Do not paste secrets into chat,
command arguments, shell history, screenshots, or clipboard managers.

## 1. Open the tool environment

```sh
nix develop --no-update-lock-file
set +x
umask 077
export SOPS_EDITOR='nvim -u NONE -i NONE -n --cmd "set noswapfile nobackup nowritebackup noundofile"'
```

These editor flags disable user configuration, history, swap, backup, and undo files.
If Neovim is unavailable, replace `nvim` with `vim` in that command.

Use SOPS for secret editing. Do not first create a plaintext file in the repository.
SOPS uses temporary plaintext while editing; keep that workspace private and
outside the repository. Do not record the editor session.

## 2. Create and back up the age identity

### 2.1 Create the identity

Use the conventional user-private location. Do not replace an existing identity.

```sh
AGE_KEY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age"
AGE_KEY_FILE="$AGE_KEY_DIR/keys.txt"
install -d -m 700 "$AGE_KEY_DIR"
if test ! -e "$AGE_KEY_FILE"; then
  age-keygen -o "$AGE_KEY_FILE"
fi
chmod 600 "$AGE_KEY_FILE"
age-keygen -y "$AGE_KEY_FILE"
```

The last command prints a public `age1...` recipient. Only that public value may
enter `.sops.yaml`. Never share the `AGE-SECRET-KEY-...` line.

### 2.2 Back up the identity in Bitwarden

Store `keys.txt` as an encrypted attachment on a dedicated Bitwarden item. Do not
paste the private identity into the item's notes or any other text field. Give the
item a clear recovery purpose, but do not put private key material in its name.

Download the attachment into a private temporary directory and confirm that the
recovery copy produces the same public recipient as the working identity. Remove
the downloaded verification copy, then lock Bitwarden when finished. Ensure the
Bitwarden account itself has a tested recovery method independent of this
workstation.

## 3. Review the root SOPS policy

### 3.1 Check the policy and recipients

1. From the repository root, open `.sops.yaml` with `nvim .sops.yaml`.
2. Verify the existing rule has this shape; do not replace its approved recipient
   with the placeholder or add a duplicate rule:

   ```yaml
   creation_rules:
     - path_regex: ^secrets/network\.yaml$
       age: age1_REPLACE_WITH_YOUR_PUBLIC_RECIPIENT
   ```

3. If a separate recovery key exists, put both full public recipients in `age`,
   separated by a comma; a backup of the same key needs no second recipient.
4. Keep other valid rules, but put this exact-path rule before any broader match.
5. Save, then inspect:

   ```sh
   find . -name .sops.yaml -print
   yq eval '.creation_rules' .sops.yaml
   ```

**Expected:** one policy file, `./.sops.yaml`, with only the intended public
recipients on the network rule; no private `AGE-SECRET-KEY-...` value.

### 3.2 Verify local SecretSpec delivery before live bootstrap

The initial policy selection check is already recorded in
[policy evidence](../../openspec/changes/establish-network-secret-operations/evidence/sops-policy-validation.md).
Retain that evidence; do not build another cryptography or backup-product test
suite as part of SecretSpec integration.

The one-time dummy check confirmed all six mappings and both scopes using
SecretSpec 0.20.0. See [delivery evidence](../../openspec/changes/establish-network-secret-operations/evidence/secretspec-validation.md).
No recurring test suite is needed for this configuration. Recheck with isolated
dummy ciphertext when the manifest mappings or SecretSpec version change; do not
use production credentials for that check.

To inspect the local tool version:

```sh
secretspec --version
```

Review root `secretspec.toml`: its SOPS provider must point to
`sops://secrets/network.yaml?sops_config=.sops.yaml`. Profile `north_york` must use
root-item references plus JSON extraction, preserving the nested YAML layout:

| Scope | Variable | Root `ref.item` | JSON extraction pointer |
|---|---|---|---|
| `opentofu` | `NB_PAT` | `netbird` | `/pat` |
| `opentofu` | `NB_MANAGEMENT_URL` | `netbird` | `/management_url` |
| `opentofu` | `TF_VAR_state_encryption_passphrase` | `opentofu` | `/state_encryption_passphrase` |
| `opnsense` | `OPNSENSE_URL` | `opnsense` | `/url` |
| `opnsense` | `OPNSENSE_API_KEY` | `opnsense` | `/api_key` |
| `opnsense` | `OPNSENSE_API_SECRET` | `opnsense` | `/api_secret` |

For each entry use `extract = { format = "json", pointer = "..." }` with its
listed pointer. All six are required; no plaintext defaults, environment
fallback provider, prompts, generation, `as_path`, or plaintext cache. Edit the
nested file through SOPS rather than SecretSpec convention-addressed writes.
Always pass a nonempty scope; unscoped execution would deliver the whole profile.
Scopes limit delivery, not decryption authority over the shared document.

Also verify the later consumer integrations locally with dummy inputs as described
in step 6. The one-time delivery check alone does not satisfy that prerequisite.
Stop before step 5 while either consumer is missing.

## 4. Approve the remote permissions

### 4.1 Bound OPNsense permissions

Discovery is complete: the GUI recorded OPNsense `26.7.3` and the official
`os-netbird` plugin installed. Group `netbird-automation` and user `svc-admin`
already exist with these four approved privileges:

- `VPN: NetBird`
- `Interfaces: Assign network ports`
- `Firewall: Alias: Edit`
- `Firewall: Rules [new]`

**These ACLs are subsystem-wide, not limited to the objects this automation
manages.** They do not grant firmware or configuration-backup access. The later
consumer must stay within the approved operations and must not silently add
privileges if an API call fails.

Before key creation, sign in locally at `https://10.10.10.1`, review **System →
Access → Groups**, then **System → Access → Users → svc-admin** and confirm:

| Field | Expected |
|---|---|
| Disabled | Unchecked, so API authentication works |
| Password | **Scrambled Password**, preventing password login |
| Group membership | `netbird-automation` only |
| Direct privileges | None |
| Login shell / SSH keys | No shell access and no authorized keys |
| Effective Privileges | Exactly the four approved ACLs; no `admins`, **All pages**, or unrelated access |

Stop on drift; do not recreate the group or user unnecessarily. The upstream
source revisions in [inspection evidence](../../openspec/changes/establish-network-secret-operations/evidence/opnsense-inspection.md)
are research references, not exact installed-code pins for this release. Later
consumer integration must confirm actual API/module compatibility.

No API key was generated during discovery. Do not generate one until step 5,
after local delivery and both later consumer integrations are verified.

### 4.2 Bound NetBird permissions

1. Sign in to the NetBird dashboard as an administrator.
The NetBird service user `Config Automation` exists with the **Network Admin**
role. Its `Infra Token` expires on 5 September 2027 and is backed up in Bitwarden.
Network Admin covers the planned Network, resource, group, router-assignment, and
policy operations, but not peer mutation or setup-key creation.

**Network Admin access covers the NetBird account, not just North York.** The
OpenTofu plan limits which objects we manage; it does not narrow the token's
permissions. The later enrollment operation needs a separately approved method
to create and retire one-use setup keys; do not widen this service user's role
silently.

## 5. Enter the live credentials through SOPS

### 5.1 Create and enter the credentials

**Gate:** local SecretSpec delivery, OpenTofu encryption/provider wiring, Ansible
credential wiring, and the permissions in step 4 are verified with dummy inputs.
Proceed only through direct SOPS editing; do not run a live consumer yet.

Then open the encrypted target using the editor settings from step 1:

```sh
export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"
install -d -m 700 secrets
sops secrets/network.yaml
```

With the editor open, create the credentials one at a time:

1. Retrieve the existing `Config Automation` service user's `Infra Token` from
   Bitwarden and transfer it directly into the SOPS editor.
2. In OPNsense, edit `svc-admin` under **System → Access → Users** and add a
   key in its **API keys / ApiKeys** section.
3. Save the one-time download in a private location outside the repository;
   transfer its `key` and `secret` into the SOPS editor.

Enter these fields in the editor, not in the shell:

- `netbird.management_url` and `netbird.pat`.
- `opnsense.url`, `opnsense.api_key`, and `opnsense.api_secret`.
- `opentofu.state_encryption_passphrase`: a unique random password-manager value
  of at least 32 characters.

The North York OPNsense URL is `https://OPNsense.localdomain`. That name resolves
to `10.10.10.1` and matches the pinned public web certificate at
`ansible/certificates/north-york-opnsense-web.pem`. NetBird Cloud uses
`https://api.netbird.io`; confirm the endpoint if using another deployment.

### 5.2 Check ciphertext and remove the download

Save and close SOPS. Inspect the file and Git diff for ciphertext and public
metadata only. Remove the downloaded OPNsense credential file. Never store a
NetBird peer setup key in this document or in OpenTofu state.

## 6. Check the consumers

### 6.1 Local prerequisites — required before step 5

Local wiring is complete. `infra/netbird/` consumes the standard NetBird
provider variables and a sensitive, ephemeral state-encryption passphrase; it
requires native encryption for state and saved plans. It currently declares no
NetBird resources. Initialize its real backend only through the later adoption
runbook with an external state path.

`ansible/playbooks/opnsense-credential-preflight.yml` reads the three
`OPNSENSE_*` variables through play-level module defaults, enables `no_log` and
pipelining, and creates no credential file. It performs local input validation
only; it does not authenticate or change the router.

A one-time SecretSpec-to-consumer check passed with temporary dummy ciphertext.
Read-only remote authentication passed. Full resource management and enrollment
remain later work.

### 6.2 Future management command shape

Run from the repository root with the explicit manifest, profile, and scope:

```text
secretspec --file secretspec.toml run --profile north_york --scope opentofu -- tofu -chdir=infra/netbird ...
secretspec --file secretspec.toml run --profile north_york --scope opnsense -- ansible-playbook <later-enrollment-playbook> ...
```

The ellipses and enrollment playbook name remain placeholders for later members.
Do not use an unscoped run or SecretSpec export/eval into the parent shell. Avoid
tracing, environment dumps, debug output, and detached child processes.

### 6.3 Recorded read-only authentication

The NetBird check read account settings through the pinned provider. The OPNsense
check used HTTP GET for `api/netbird/status/status` through
`ansible/playbooks/opnsense-credential-preflight.yml`. Both ran under their
matching SecretSpec scopes, suppressed consumer output, and made no remote
change. See the change evidence for the recorded result.

The pinned OPNsense certificate expires on 28 October 2026. Replace it only after
verifying the new public certificate against the live endpoint; a mismatch must
fail closed.

SecretSpec scopes narrow which declared inputs a child receives; they do not
stop an operator process with the age identity from decrypting the shared file.

## Recover the age identity

1. Retrieve the Bitwarden `keys.txt` attachment into a mode-`0700` temporary
   directory outside the repository.
2. Run `age-keygen -y` against the retrieved file and compare the resulting
   public recipient with the recipient declared in `.sops.yaml`.
3. Stop if the file does not parse or the recipients differ. Do not display or
   record the private identity.
4. If recovery is not currently required, remove the downloaded copy and lock
   Bitwarden. If recovery is required, install it at the conventional SOPS path
   with directory mode `0700` and file mode `0600`.

## Rotate or revoke

### 1. Rotate a credential

For a credential rotation, create the replacement, edit it through SOPS, prove
read-only authentication, then revoke the predecessor. Do not revoke the working
credential before the replacement passes.

### 2. Rotate an age key

For an age-key rotation, add and verify the replacement public recipient, run
`sops updatekeys secrets/network.yaml`, and prove recovery before removing an old
recipient. If a decryption key was exposed, also rotate the underlying credentials;
changing recipients cannot protect copies of old ciphertext.

### 3. Revoke remote access and record results

Delete a revoked PAT in NetBird and an API key in OPNsense. Deleting the local
encrypted file does not revoke remote access. Revoke and replace exposed values;
do not treat editing Git history as sufficient recovery.

Record only dates, public fingerprints, non-secret credential identifiers,
approved privileges, and results. Do not store secret values or decrypted output.

## Sources

- [Planned change](../../openspec/changes/establish-network-secret-operations/).
- [SecretSpec SOPS provider](https://secretspec.dev/providers/sops/).
- [SecretSpec configuration](https://secretspec.dev/reference/configuration/).
- [SecretSpec scopes](https://secretspec.dev/concepts/scopes/).
- [SOPS](https://getsops.io/docs/).
- [age](https://age-encryption.org/).
- [NetBird API access](https://docs.netbird.io/how-to/access-netbird-public-api).
- [OPNsense users and privileges](https://docs.opnsense.org/manual/users.html).
- [OPNsense API key creation](https://docs.opnsense.org/development/how-tos/api.html#creating-keys).
