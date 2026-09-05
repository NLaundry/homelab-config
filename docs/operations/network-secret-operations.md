# Network secret operations

This runbook creates the encrypted credentials for NetBird and OPNsense automation. SOPS encrypts the credential file. `age` supplies the encryption key.

The encrypted file contains:

- the NetBird management URL and personal access token (PAT)
- the North York OPNsense API key and secret
- the OpenTofu state-encryption passphrase

Do not store a NetBird peer setup key in this file. The enrollment process creates and deletes that key when it needs it.

## 1. Open the development shell

The Nix shell supplies the tested tools. You do not need Homebrew or another installer.

Install Nix first if `nix --version` fails: <https://nixos.org/download/>

Run these commands from the repository root:

```sh
nix develop --no-update-lock-file
set +x
umask 077
```

Confirm the required tools:

```sh
for name in sops age-keygen nano tofu ansible-playbook; do
  command -v "$name"
done
```

Each path must start with `/nix/store/`.

## 2. Create the age identity

The public age recipient encrypts files. The private identity decrypts them and must stay outside this repository.

```sh
AGE_KEY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age"
AGE_KEY_FILE="$AGE_KEY_DIR/keys.txt"
install -d -m 700 "$AGE_KEY_DIR"

if test -e "$AGE_KEY_FILE"; then
  echo "Using existing key: $AGE_KEY_FILE"
else
  age-keygen -o "$AGE_KEY_FILE"
fi

chmod 600 "$AGE_KEY_FILE"
age-keygen -y "$AGE_KEY_FILE"
```

The last command must print one public value that starts with `age1`.

It is safe to add the `age1...` value to `.sops.yaml`. Never copy a line that starts with `AGE-SECRET-KEY-` into Git, chat, or documentation.

## 3. Back up the age identity

Without the private identity, you cannot decrypt the SOPS file. Store one copy in an encrypted password manager or encrypted volume.

For an encrypted volume, replace the example path:

```sh
RECOVERY_DIR='/Volumes/REPLACE-WITH-ENCRYPTED-VOLUME/homelab-config'
install -d -m 700 "$RECOVERY_DIR"
install -m 600 "$AGE_KEY_FILE" "$RECOVERY_DIR/sops-age-keys.txt"

test "$(age-keygen -y "$AGE_KEY_FILE")" = \
  "$(age-keygen -y "$RECOVERY_DIR/sops-age-keys.txt")"
```

The `test` command succeeds without output. Lock or unmount the recovery location.

## 4. Register the public recipient

When Task 2.3 starts, provide the output from this command:

```sh
age-keygen -y "$AGE_KEY_FILE"
```

The implementation adds this public value to the root `.sops.yaml`. The rule must select `secrets/network.yaml`. Do not create a second `.sops.yaml`.

After the policy exists, inspect it:

```sh
yq eval '.creation_rules' .sops.yaml
```

## 5. Create the remote credentials

### NetBird PAT

The PAT lets OpenTofu manage NetBird without your interactive login.

Open the NetBird dashboard and select:

**User menu → Personal Access Token → Create Token**

Use the name `homelab-config-network-foundation`. Choose a practical expiry date.

NetBird PATs inherit their user's permissions. The PAT form does not provide separate scopes. Use the least-privileged user that can manage the required network objects.

For NetBird Cloud, the management URL is:

```text
https://api.netbird.io
```

Keep the new token page open until you enter the token through SOPS.

Documentation: <https://docs.netbird.io/how-to/access-netbird-public-api>

### OPNsense API key

The dedicated user keeps Ansible separate from your personal administrator account.

Do this only after Task 2.4 confirms the required privileges on the installed OPNsense version.

Open `https://10.10.10.1`, then create this group:

**System → Access → Groups → Add**

- Name: `homelab-automation`
- Privileges: only the privileges approved by Task 2.4

Create this user:

**System → Access → Users → Add**

- Username: `homelab-automation`
- Group: `homelab-automation`
- Do not add the user to `admins`

Open the saved user. Confirm its **Effective Privileges**. Create one credential pair in the **API keys** section.

OPNsense shows the API secret once. Keep the downloaded credential file only until the next step. Do not grant **All pages** to bypass a missing privilege.

Documentation:

- <https://docs.opnsense.org/manual/users.html>
- <https://docs.opnsense.org/development/api.html>
- <https://github.com/opnsense/plugins/tree/master/security/netbird>

## 6. Create the encrypted file

Open the target directly through SOPS. This prevents a plaintext credential file from existing in the repository.

```sh
export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"
install -d -m 700 secrets
EDITOR='nano --ignorercfiles --tempfile --nonewlines --nohelp' \
  sops secrets/network.yaml
```

Enter this YAML in Nano:

```yaml
netbird:
  management_url: "https://api.netbird.io"
  pat: "PASTE-IN-EDITOR"
opnsense:
  url: "https://10.10.10.1"
  api_key: "PASTE-IN-EDITOR"
  api_secret: "PASTE-IN-EDITOR"
opentofu:
  state_encryption_passphrase: "PASTE-IN-EDITOR"
```

Use your password manager to generate a unique state passphrase of at least 32 random characters.

Save and close Nano. SOPS encrypts each value before it writes the file. Delete the downloaded OPNsense credential file.

## 7. Verify the result

These checks confirm encryption without printing secret values:

```sh
grep -Eq '^  pat: ENC\[AES256_GCM,' secrets/network.yaml
grep -Eq '^  api_key: ENC\[AES256_GCM,' secrets/network.yaml
grep -Eq '^  api_secret: ENC\[AES256_GCM,' secrets/network.yaml
grep -Eq '^  state_encryption_passphrase: ENC\[AES256_GCM,' secrets/network.yaml
grep -Eq '^sops:' secrets/network.yaml
```

Confirm that SOPS can decrypt the expected fields. Discard the output:

```sh
sops --decrypt --output-type json secrets/network.yaml \
  | jq -e '
      (.netbird.management_url | length > 0) and
      (.netbird.pat | length > 0) and
      (.opnsense.url | length > 0) and
      (.opnsense.api_key | length > 0) and
      (.opnsense.api_secret | length > 0) and
      (.opentofu.state_encryption_passphrase | length >= 32)
    ' >/dev/null
```

Inspect the Git diff. It must contain only ciphertext and public recipients:

```sh
git diff -- .sops.yaml secrets/network.yaml
! git diff -- .sops.yaml secrets/network.yaml | grep -q 'AGE-SECRET-KEY-'
```

Run the repository checks after the adapters exist:

```sh
nix develop --command bats tests/secrets/contracts.bats
```

## 8. Check live authentication

These read-only checks prove that the credentials work before configuration changes start:

```sh
./scripts/network-tofu -chdir=infra/netbird plan -refresh-only
./scripts/network-ansible ansible-playbook \
  ansible/playbooks/opnsense-netbird.yml \
  --check --tags preflight
```

Run them only after the adapters and IaC files exist. Neither command may propose a remote change.

## Recovery drill

The drill proves that the backup can decrypt dummy ciphertext. It does not expose production values.

```sh
RECOVERY_KEY_FILE="$RECOVERY_DIR/sops-age-keys.txt"
test -f "$RECOVERY_KEY_FILE"
test "$(age-keygen -y "$RECOVERY_KEY_FILE")" = \
  "$(age-keygen -y "$AGE_KEY_FILE")"
SOPS_AGE_KEY_FILE="$RECOVERY_KEY_FILE" \
  sops --decrypt tests/secrets/fixtures/recovery-dummy.enc.yaml >/dev/null
```

Record the date, public recipient, fixture name, and result. Do not record the private key or decrypted output.

## Credential rotation

Replace one credential at a time:

1. Create the replacement PAT or API key.
2. Edit only that value with `sops secrets/network.yaml`.
3. Run its read-only authentication check.
4. Revoke the old credential after the check succeeds.

For an age-key change, add the new public recipient first. Then run:

```sh
sops updatekeys secrets/network.yaml
```

Prove that the new key can decrypt the file before you remove the old recipient.

## Revoke access

- Delete the PAT from NetBird **Personal Access Token** settings.
- Delete the API key from the `homelab-automation` OPNsense user.
- Disable the OPNsense user if no automation needs it.
- Re-encrypt all managed SOPS files if an age identity is lost or exposed.

Deleting the encrypted file does not revoke a remote credential.

## Safe evidence

Record only dates, public `age1...` recipients, non-secret credential identifiers, OPNsense privilege names, and pass/fail results.

Do not record tokens, API secrets, private age identities, decrypted output, credential downloads, or editor screenshots.

## References

- SOPS: <https://getsops.io/docs/>
- age: <https://age-encryption.org/>
- OpenTofu state encryption: <https://opentofu.org/docs/language/state/encryption/>
- NetBird provider: <https://registry.terraform.io/providers/netbirdio/netbird/latest/docs>
- OPNsense NetBird API controllers: <https://github.com/opnsense/plugins/tree/master/security/netbird/src/opnsense/mvc/app/controllers/OPNsense/Netbird/Api>
