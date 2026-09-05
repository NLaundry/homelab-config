# Prepare network secret custody

## What

Keep NetBird and OPNsense credentials in `secrets/network.yaml`, encrypted with
SOPS and age. Keep private decryption identities outside Git and the Nix store.

## Why

Automation needs credentials. It must not leave plaintext files, logs, or shared
shell variables behind. A separate recovery copy prevents permanent loss of access.

## Before you start

**This runbook is a draft.** The tools exist, but `.sops.yaml`, the encrypted
network file, consumer adapters, and secret tests do not yet exist. Review their
implementation before creating live credentials or running consumers.

You need local OPNsense access, NetBird administrator access, and an encrypted
recovery location independent of this workstation. Do not paste secrets into chat,
command arguments, shell history, screenshots, or clipboard managers.

## 1. Open the tool environment

```sh
nix develop --no-update-lock-file
set +x
umask 077
```

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

### 2.2 Back up the identity

Copy the private identity to an encrypted password-manager attachment or separate
encrypted volume. Confirm that the recovery copy produces the same public
recipient. Lock the recovery location when finished.

## 3. Review the root SOPS policy

### 3.1 Check the policy and recipients

After implementation, inspect the public policy:

```sh
yq eval '.creation_rules' .sops.yaml
```

Confirm that one root policy selects `secrets/network.yaml` and only the approved
custody recipients. If you use a separate recovery identity, include its approved
public recipient too. Do not add a second policy in a subdirectory.

### 3.2 Test with dummy values

First encrypt dummy values. Prove that intended identities can decrypt them and
an unrelated identity cannot. Keep dummy ciphertext for the recovery drill.
Do not introduce production values until these checks pass.

## 4. Approve the remote permissions

### 4.1 Bound OPNsense permissions

From local OPNsense, record the installed release and available API/plugin
privilege names. Review the operations required for package installation, NetBird
settings and service control, interfaces, firewall rules, backup, and reload.

Create a dedicated automation user only if those permissions can be bounded.
Do not grant `admins` or **All pages** to work around missing API support.
Stop if the installed release cannot support the planned operations safely.

### 4.2 Bound NetBird permissions

For NetBird, use a dedicated account with the least privilege needed for the
planned objects and enrollment API. PATs inherit their user's permissions; they
do not have separate per-token scopes. Choose an expiry and a rotation date.

## 5. Enter the live credentials through SOPS

### 5.1 Create and enter the credentials

Create the NetBird PAT and OPNsense API key only after the permission review.
Then open the encrypted target directly:

```sh
export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"
install -d -m 700 secrets
EDITOR='nano --ignorercfiles --tempfile --nonewlines --nohelp' \
  sops secrets/network.yaml
```

Enter these fields in the editor, not in the shell:

- `netbird.management_url` and `netbird.pat`.
- `opnsense.url`, `opnsense.api_key`, and `opnsense.api_secret`.
- `opentofu.state_encryption_passphrase`: a unique random password-manager value
  of at least 32 characters.

The North York OPNsense URL is `https://10.10.10.1`. NetBird Cloud uses
`https://api.netbird.io`; confirm the endpoint if using another deployment.

### 5.2 Check ciphertext and remove the download

Save and close SOPS. Inspect the file and Git diff for ciphertext and public
metadata only. Remove the downloaded OPNsense credential file. Never store a
NetBird peer setup key in this document or in OpenTofu state.

## 6. Check the consumers

After the adapters and their dummy-data tests exist:

1. Check process-local OpenTofu environment delivery and private volatile Ansible
   credential files with mode `0600`.
2. Check cleanup on success, failure, and interruption. Reject tracing, unsafe
   temporary paths, and leftover decrypted files.
3. Run each adapter's documented read-only authentication check. Confirm that
   output contains no secrets and neither remote system changes.

The current repository has no consumer command to run yet. Do not substitute
an environment dump or a later stack's apply operation for this check.

## Recovery drill

Use an isolated environment that has the recovery identity but not the primary
identity. Decrypt the retained dummy ciphertext with the recovery copy and discard
the plaintext output. Do not move or delete the working primary identity merely
to perform the drill. Stop if the backup cannot decrypt the fixture.

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
- [SOPS](https://getsops.io/docs/).
- [age](https://age-encryption.org/).
- [NetBird API access](https://docs.netbird.io/how-to/access-netbird-public-api).
- [OPNsense users and privileges](https://docs.opnsense.org/manual/users.html).
