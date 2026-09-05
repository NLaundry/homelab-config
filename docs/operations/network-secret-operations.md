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

### 2.2 Back up the identity

Copy the private identity to an encrypted password-manager attachment or separate
encrypted volume. Confirm that the recovery copy produces the same public
recipient. Lock the recovery location when finished.

## 3. Review the root SOPS policy

### 3.1 Check the policy and recipients

1. From the repository root, open `.sops.yaml` with `nvim .sops.yaml`.
2. Add this rule, replacing the example recipient with the public value from step 2:

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

### 3.2 Test with dummy values

Run this from the repository root after step 2, with `AGE_KEY_FILE` still set.
It uses the real policy but creates no live credentials or `secrets/network.yaml`.

```sh
(
  set -eu
  umask 077
  CHECK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/homelab-sops-check.XXXXXX")
  mkdir "$CHECK_DIR/empty-home"
  printf 'check: dummy-only\n' > "$CHECK_DIR/plain.yaml"

  sops --encrypt --config "$PWD/.sops.yaml" \
    --filename-override "$PWD/secrets/network.yaml" \
    "$CHECK_DIR/plain.yaml" > "$CHECK_DIR/network.enc.yaml"
  yq '.sops.age[].recipient' "$CHECK_DIR/network.enc.yaml"

  env -i PATH="$PATH" HOME="$CHECK_DIR/empty-home" \
    XDG_CONFIG_HOME="$CHECK_DIR/empty-home" SOPS_AGE_KEY_FILE="$AGE_KEY_FILE" \
    sops --decrypt "$CHECK_DIR/network.enc.yaml" > "$CHECK_DIR/decrypted.yaml"
  cmp "$CHECK_DIR/plain.yaml" "$CHECK_DIR/decrypted.yaml"

  age-keygen -o "$CHECK_DIR/unrelated.age" 2>/dev/null
  if env -i PATH="$PATH" HOME="$CHECK_DIR/empty-home" \
    XDG_CONFIG_HOME="$CHECK_DIR/empty-home" SOPS_AGE_KEY_FILE="$CHECK_DIR/unrelated.age" \
    sops --decrypt "$CHECK_DIR/network.enc.yaml" >/dev/null 2>&1; then
    printf 'FAIL: unrelated key decrypted the fixture\n' >&2
    exit 1
  fi

  rm "$CHECK_DIR/plain.yaml" "$CHECK_DIR/decrypted.yaml" "$CHECK_DIR/unrelated.age"
  printf 'PASS: intended key works; unrelated key is denied\nRecovery fixture: %s\n' \
    "$CHECK_DIR/network.enc.yaml"
)
```

**Expected:** the recipient list matches step 3.1, followed by `PASS` and a fixture
path; any earlier error or different recipient means stop.

The empty home and cleared environment prevent SOPS from silently using another
installed key. Copy the encrypted fixture into the recovery storage from step 2;
if you added a separate recovery key, test it with the [recovery command](#recovery-drill).
Do not add production values until these checks pass.

## 4. Approve the remote permissions

### 4.1 Bound OPNsense permissions

1. Sign in locally at `https://10.10.10.1` with your administrator account.
2. Open **System → Firmware → Status** and record the OPNsense version.
3. Open **System → Firmware → Plugins**, search for `os-netbird`, and record
   whether it is installed or available; do not install it during this step.
4. In **System → Access → Groups**, inspect the available privileges for
   NetBird, interfaces, firewall, firmware, configuration backup, and reload.
   Match each privilege to an operation required by the enrollment role.

**Stop here until the enrollment implementation supplies the exact privilege
list for this release.** That list does not exist yet; selecting every matching
privilege is not a substitute, and missing plugin privileges are a blocker.

Once that list is approved:

5. Create group `netbird-automation` with only those privileges.
6. Under **System → Access → Users**, create this account:

   | Field | Value |
   |---|---|
   | Username | `svc-netbird` |
   | Description / full name | North York NetBird automation |
   | Disabled | Unchecked, so API authentication works |
   | Password | Use **Scrambled Password** to prevent password login |
   | Group membership | `netbird-automation` only |
   | Login shell / SSH keys | No shell access and no authorized keys |

7. Save and inspect group membership and **Effective Privileges**; stop if you
   find `admins`, **All pages**, or unrelated access.

Do not generate its API key until step 5, when SOPS is ready to receive it.

### 4.2 Bound NetBird permissions

1. Sign in to the NetBird dashboard as an administrator.
2. Open **Team → Service Users** and create `homelab-opentofu`.
3. Select **Admin** for the planned OpenTofu writes; **User** is read-only.
4. Confirm it is a service user, not a personal user or an invited human account.

**Admin access covers the NetBird account, not just North York.** The OpenTofu
plan limits which objects we manage; it does not narrow the token's permissions.
Do not use your personal account's token.

Create its token in step 5; use `north-york-opentofu` as the name, a suggested
90-day expiry, and a rotation reminder seven days before expiry.

## 5. Enter the live credentials through SOPS

### 5.1 Create and enter the credentials

First open the encrypted target using the editor settings from step 1:

```sh
export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"
install -d -m 700 secrets
sops secrets/network.yaml
```

With the editor open, create the credentials one at a time:

1. In NetBird, open `homelab-opentofu` under **Team → Service Users** and add an
   access token with the name and expiry from step 4.2.
2. Transfer the token directly into the SOPS editor before closing the token
   dialog; NetBird will not show the value again.
3. In OPNsense, edit `svc-netbird` under **System → Access → Users** and add a
   key in its **API keys / ApiKeys** section.
4. Save the one-time download in a private location outside the repository;
   transfer its `key` and `secret` into the SOPS editor.

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

1. Restore the backed-up key and dummy fixture into a private folder outside the
   repository; do not move or delete the working primary key.
2. Replace the two paths below with those restored files, then run:

```sh
RECOVERY_KEY_FILE='/absolute/path/to/restored/keys.txt'
RECOVERY_FIXTURE='/absolute/path/to/restored/network.enc.yaml'
(
  set -eu
  RECOVERY_HOME=$(mktemp -d "${TMPDIR:-/tmp}/homelab-sops-recovery.XXXXXX")
  trap 'rmdir "$RECOVERY_HOME"' EXIT
  env -i PATH="$PATH" HOME="$RECOVERY_HOME" XDG_CONFIG_HOME="$RECOVERY_HOME" \
    SOPS_AGE_KEY_FILE="$RECOVERY_KEY_FILE" \
    sops --decrypt "$RECOVERY_FIXTURE" >/dev/null
  printf 'PASS: recovery key decrypts the dummy fixture\n'
)
```

**Expected:** `PASS`; otherwise stop and fix the backup before adding or rotating
live credentials. Lock the restored private key away again when finished.

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
- [OPNsense API key creation](https://docs.opnsense.org/development/how-tos/api.html#creating-keys).
