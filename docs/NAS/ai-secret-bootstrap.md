# Runbook: Bootstrap AI secrets with age and SOPS

**Host:** NASty (`operator@10.10.10.11` by default)
**Change:** `establish-ai-secret-operations`
**When to use:** Run once while applying the first AI-gateway stack member, then repeat only when adding recipients or rotating credentials.

> **Secret-handling rule:** Never paste private keys or credential values into chat, command arguments, shell variables, logs, evidence, or Git. Enter values only through a password manager and the interactive SOPS editor. Disable shell tracing before beginning.

---

## 0. Prerequisites

- Work from the repository root.
- Use the repository environment after task 1.1 adds `sops`, `age`, `ssh-to-age`, `ssh-keygen`, `ssh-keyscan`, and `nano`:

  ```bash
  nix develop
  set -euo pipefail
  set +x
  umask 077
  ```

  Run the remainder of the procedure in this same fail-fast Bash shell.

- Confirm NASty's Ed25519 host key is already enrolled in `~/.ssh/known_hosts`:

  ```bash
  NASTY_ADDRESS=10.10.10.11
  if ssh-keygen -F "$NASTY_ADDRESS" >/dev/null; then
    printf '%s\n' 'NASty host key is enrolled'
  else
    printf '%s\n' 'NASty host key requires verified enrollment below'
  fi
  ```

  If this fails on a clean workstation, collect a candidate without trusting it yet:

  ```bash
  CANDIDATE_HOST_KEY="$(mktemp)"
  ssh-keyscan -t ed25519 "$NASTY_ADDRESS" >"$CANDIDATE_HOST_KEY"
  ssh-keygen -lf "$CANDIDATE_HOST_KEY"
  ```

  Compare that fingerprint with `sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` shown on NASty's local console or another independently trusted channel. **Do not continue on a mismatch.** Only after an exact match, enroll the candidate:

  ```bash
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  cat "$CANDIDATE_HOST_KEY" >>"$HOME/.ssh/known_hosts"
  chmod 600 "$HOME/.ssh/known_hosts"
  rm -f "$CANDIDATE_HOST_KEY"
  ```

- Confirm strict SSH and passwordless deployment sudo work:

  ```bash
  NASTY_TARGET="operator@$NASTY_ADDRESS"
  ssh -o StrictHostKeyChecking=yes -o BatchMode=yes \
    "$NASTY_TARGET" 'sudo -n true'
  ```

- Have access to:
  - the OpenRouter account;
  - a password manager or equivalent encrypted recovery store;
  - an independently trusted way to verify NASty's Ed25519 SSH host-key fingerprint.

Stop if any prerequisite fails. Do not weaken or disable the fail-fast shell settings during this procedure.

---

## 1. Create or reuse the operator age identity

Use the standard SOPS age location unless an existing operator identity is already managed elsewhere. Reject relative paths and any path inside the repository:

```bash
REPO_ROOT="$(pwd -P)"
case "${XDG_CONFIG_HOME:-}" in
  "") CONFIG_ROOT="$HOME/.config" ;;
  /*) CONFIG_ROOT="$XDG_CONFIG_HOME" ;;
  *) printf '%s\n' 'XDG_CONFIG_HOME must be absolute' >&2; exit 1 ;;
esac
AGE_KEY_DIR="$CONFIG_ROOT/sops/age"
mkdir -p "$AGE_KEY_DIR"
AGE_KEY_DIR="$(cd "$AGE_KEY_DIR" && pwd -P)"
AGE_KEY_FILE="$AGE_KEY_DIR/keys.txt"
case "$AGE_KEY_FILE" in
  "$REPO_ROOT"/*) printf '%s\n' 'age identity must be outside the repository' >&2; exit 1 ;;
esac
chmod 700 "$AGE_KEY_DIR"
```

If the file already exists, **do not overwrite it**. Reject symlinks, non-regular files, and permissions other than `0600` before deriving its public recipient:

```bash
if test -e "$AGE_KEY_FILE"; then
  test -f "$AGE_KEY_FILE"
  test ! -L "$AGE_KEY_FILE"
  case "$(uname -s)" in
    Darwin) AGE_KEY_MODE="$(stat -f '%Lp' "$AGE_KEY_FILE")" ;;
    Linux) AGE_KEY_MODE="$(stat -c '%a' "$AGE_KEY_FILE")" ;;
    *) printf '%s\n' 'unsupported operator system' >&2; exit 1 ;;
  esac
  test "$AGE_KEY_MODE" = 600
  age-keygen -y "$AGE_KEY_FILE"
fi
```

If it does not exist, create it and lock its permissions:

```bash
test ! -e "$AGE_KEY_FILE"
age-keygen -o "$AGE_KEY_FILE"
chmod 600 "$AGE_KEY_FILE"
age-keygen -y "$AGE_KEY_FILE"
```

`age-keygen -y` prints only the public recipient. Record that `age1...` recipient for `.sops.yaml`; do not record the `AGE-SECRET-KEY-...` identity anywhere in the repository.

### Recovery checkpoint

Back up the private identity to an encrypted password-manager item or encrypted offline medium. Verify restoration outside the repository without touching the live identity:

Perform recovery verification in a scoped fail-fast shell with signal-safe cleanup. It rejects relative, repository-local, or symlink-resolved temporary locations:

```bash
(
  set -euo pipefail
  RECOVERY_BASE="${TMPDIR:-/tmp}"
  case "$RECOVERY_BASE" in /*) ;; *) exit 1 ;; esac
  RECOVERY_BASE="$(cd "$RECOVERY_BASE" && pwd -P)"
  case "$RECOVERY_BASE" in "$REPO_ROOT"|"$REPO_ROOT"/*) exit 1 ;; esac
  RECOVERY_DIR="$(mktemp -d "$RECOVERY_BASE/ai-age-recovery.XXXXXX")"
  RECOVERY_DIR="$(cd "$RECOVERY_DIR" && pwd -P)"
  case "$RECOVERY_DIR" in "$REPO_ROOT"|"$REPO_ROOT"/*) exit 1 ;; esac
  chmod 700 "$RECOVERY_DIR"
  RECOVERY_KEY="$RECOVERY_DIR/keys.txt"
  cleanup() {
    rm -f "$RECOVERY_KEY"
    rmdir "$RECOVERY_DIR" 2>/dev/null || true
  }
  trap cleanup EXIT
  trap 'exit 129' HUP
  trap 'exit 130' INT
  trap 'exit 143' TERM
  printf 'Restore the recovery attachment directly to: %s\n' "$RECOVERY_KEY"
  printf '%s' 'Press Enter after the password manager finishes the restore: '
  IFS= read -r _
  test -f "$RECOVERY_KEY"
  test ! -L "$RECOVERY_KEY"
  chmod 600 "$RECOVERY_KEY"
  test "$(age-keygen -y "$AGE_KEY_FILE")" = \
    "$(age-keygen -y "$RECOVERY_KEY")"
)
```

Prefer a RAM-backed `TMPDIR` when available. Do not proceed until there are two independently controlled copies: the operator file and the verified recovery copy.

---

## 2. Derive and verify NASty's age recipient

Retrieve only NASty's **public** Ed25519 host key:

```bash
NASTY_TARGET="operator@10.10.10.11"
NASTY_HOST_KEY="$(mktemp)"
trap 'rm -f "$NASTY_HOST_KEY"' EXIT

ssh -o StrictHostKeyChecking=yes "$NASTY_TARGET" \
  'sudo cat /etc/ssh/ssh_host_ed25519_key.pub' >"$NASTY_HOST_KEY"
```

Display its fingerprint:

```bash
ssh-keygen -lf "$NASTY_HOST_KEY"
```

Compare that fingerprint with an independently trusted value, such as local-console output from NASty:

```bash
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

Stop if the fingerprints differ. After verification, derive the public age recipient:

```bash
ssh-to-age <"$NASTY_HOST_KEY"
```

Record only the resulting `age1...` recipient. The private host key must remain on NASty and must never be copied into this repository.

---

## 3. Configure the recipient policy

The implementation must place both public recipients in `.sops.yaml` for `secrets/ai.yaml`:

```yaml
creation_rules:
  - path_regex: ^secrets/ai\.yaml$
    key_groups:
      - age:
          - <operator-age-recipient>
          - <NASty-ssh-derived-age-recipient>
```

Checks:

- Both entries begin with `age1`.
- Neither entry contains `AGE-SECRET-KEY-`.
- The path rule matches only `secrets/ai.yaml`.
- No recipient is removed during rotation until re-encryption with its replacement succeeds.

---

## 4. Create the two credentials

### OpenRouter API key

In the OpenRouter account:

1. Create a dedicated key for this homelab gateway.
2. Apply the smallest practical hard spending limit.
3. Store it in the password manager.
4. Do not paste it into chat, a shell command, or a plaintext file.

### LiteLLM master key

Generate a separate 48-character value using only `A-Z`, `a-z`, `0-9`, `_`, and `-` through the password manager's cryptographic password generator. Store it as a distinct password-manager field or item. It must not reuse the OpenRouter key or an existing password.

Keep both values available only through the password manager's copy function for the next step.

---

## 5. Create the encrypted document

Create the directory without creating a plaintext secret file:

```bash
mkdir -p secrets
export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"
```

Open the target directly with SOPS using the repository-managed Nano editor. Nano does not load user plugins and these options avoid backup creation and unnecessary editor state:

```bash
EDITOR='nano --ignorercfiles --tempfile --nonewlines --nohelp' \
  sops secrets/ai.yaml
```

Enter exactly these two quoted top-level keys. Prefer password-manager auto-type. If auto-type is unavailable, disable clipboard history, paste one value at a time, and clear the clipboard immediately after each paste:

```yaml
OPENROUTER_API_KEY: "<paste value>"
LITELLM_MASTER_KEY: "<paste base64url-compatible value>"
```

Save and exit. SOPS must encrypt the values before writing `secrets/ai.yaml`.

---

## 6. Verify ciphertext without revealing values

Confirm the file contains SOPS ciphertext and both expected key names:

```bash
grep -Eq '^OPENROUTER_API_KEY: ENC\[AES256_GCM,' secrets/ai.yaml
grep -Eq '^LITELLM_MASTER_KEY: ENC\[AES256_GCM,' secrets/ai.yaml
grep -Eq '^sops:' secrets/ai.yaml
```

Confirm the operator identity can decrypt and that the decrypted document has exactly the expected keys. Output is discarded:

```bash
SOPS_AGE_KEY_FILE="$AGE_KEY_FILE" \
  sops --decrypt --output-type json secrets/ai.yaml \
  | jq -e '
      (keys | sort == ["LITELLM_MASTER_KEY", "OPENROUTER_API_KEY"]) and
      all(.[]; type == "string" and length > 0)
    ' >/dev/null
```

Inspect only repository status, recipient policy, and public recipient metadata:

```bash
git status --short -- .sops.yaml secrets/ai.yaml
yq eval '.sops.age[].recipient' secrets/ai.yaml
```

Stage both newly created files so the Git-backed Nix flake includes them, then inspect the staged ciphertext and policy. Staging does not authorize a commit:

```bash
git add -- .sops.yaml secrets/ai.yaml
git diff --cached -- .sops.yaml secrets/ai.yaml
! git diff --cached -- .sops.yaml secrets/ai.yaml | grep -q 'AGE-SECRET-KEY-'
```

Run the repository contracts once implemented:

```bash
make test-tooling
nix run .#harness -- tests/secrets/contracts.bats
for check in conformance targets scopes records; do
  SPEC_ROOT=specbase/changes/establish-ai-secret-operations/specs \
    nix develop --no-update-lock-file --command \
      tests/specbase/enforcement-quality.sh "$check"
done
nix run .#specbase -- validate establish-ai-secret-operations \
  --type change --strict
```

The implementation must first add direct entries for the new automated bindings to `tests/specbase/enforcement-observations.json`. Stop if a test reports plaintext, a private identity, a missing recipient, an unsafe output path, or an absent observation.

---

## 7. Deploy host-side decryption

Pin deployment and direct SSH to the same verified target and strict host-key policy. Record the exact pre-change system closure for rollback, then build before activation:

```bash
NASTY_TARGET="${NASTY_TARGET:-operator@10.10.10.11}"
KEY="${KEY:-$HOME/.ssh/id_ed25519}"
export NIX_SSHOPTS="-i $KEY -o StrictHostKeyChecking=yes -o BatchMode=yes"
PREVIOUS_SYSTEM="$(ssh -o StrictHostKeyChecking=yes -o BatchMode=yes \
  -i "$KEY" "$NASTY_TARGET" 'readlink -f /run/current-system')"
case "$PREVIOUS_SYSTEM" in /nix/store/*) ;; *) exit 1 ;; esac
ssh -o StrictHostKeyChecking=yes -o BatchMode=yes -i "$KEY" \
  "$NASTY_TARGET" "test -x '$PREVIOUS_SYSTEM/bin/switch-to-configuration'"
make build TARGET="$NASTY_TARGET" KEY="$KEY"
```

Temporarily activate and run normal deployed verification:

```bash
make try TARGET="$NASTY_TARGET" KEY="$KEY"
```

The selected runtime file is `/run/secrets-rendered/ai.env`. Verify only its location, ownership, mode, and key names—never print its values:

```bash
ssh -o StrictHostKeyChecking=yes -o BatchMode=yes -i "$KEY" \
  "$NASTY_TARGET" 'sudo bash -s' <<'REMOTE'
set -euo pipefail
path=/run/secrets-rendered/ai.env
test -f "$path"
resolved="$(readlink -f "$path")"
case "$resolved" in /run/*) ;; *) exit 1 ;; esac
stat -Lc '%U:%G %a' "$path" | grep -qx 'root:root 400'
awk -F= '
  $1 == "OPENROUTER_API_KEY" { openrouter++ }
  $1 == "LITELLM_MASTER_KEY" { litellm++ }
  END { exit !(NR == 2 && openrouter == 1 && litellm == 1) }
' "$path"
REMOTE
```

After temporary activation and verification succeed, persist the generation through the normal reviewed deployment operation:

```bash
make deploy TARGET="$NASTY_TARGET" KEY="$KEY"
```

A later maintenance reboot must reproduce the same runtime file and checks. Do not reboot solely for this runbook without confirming the normal host rollback path first.

---

## 8. Record sanitized evidence

Record only:

- the two public age recipients or their short fingerprints, plus the independently observed NASty Ed25519 fingerprint-to-recipient provenance;
- successful tool and secret-contract test names;
- successful build/activation operation;
- runtime path, owner, group, and mode;
- the date and operator identity used for the procedure.

Add the sanitized production-recipient record under `## ai-secret-recipient-provenance` in `tests/specbase/manual-verification.md`. Include the tested revision/generation, environment/persona, UTC observation time and freshness boundary, independently observed Ed25519 fingerprint, derived public age recipient, limitations, blast radius, and cleanup/result. Never include a private key or credential value.

Do not record:

- credential values;
- decrypted output;
- private age identity contents;
- private SSH host-key contents;
- terminal screenshots containing clipboard or editor contents.

---

## Rollback

Rollback removes the sops-nix runtime declaration and activation while preserving:

- encrypted `secrets/ai.yaml`;
- `.sops.yaml` public recipients;
- the operator's private age identity and recovery backup;
- NASty's SSH host identity.

Keep the `PREVIOUS_SYSTEM` value captured before activation in the same shell. Verify it is a Nix store system closure, activate it explicitly, and confirm the runtime path disappears:

```bash
case "$PREVIOUS_SYSTEM" in /nix/store/*) ;; *) exit 1 ;; esac
ssh -o StrictHostKeyChecking=yes -o BatchMode=yes -i "$KEY" \
  "$NASTY_TARGET" \
  "sudo '$PREVIOUS_SYSTEM/bin/switch-to-configuration' switch"
ssh -o StrictHostKeyChecking=yes -o BatchMode=yes -i "$KEY" \
  "$NASTY_TARGET" \
  'sudo test ! -e /run/secrets-rendered/ai.env'
```

Stop and investigate if exact prior-generation activation fails or the path remains. Do not delete ciphertext or identities merely to prove rollback. If a credential value was exposed, revoke or rotate that credential first; configuration rollback alone does not invalidate it.

---

## Recipient rotation

For an operator age-identity replacement:

1. Add and independently verify the replacement public recipient.
2. Re-encrypt with `sops updatekeys secrets/ai.yaml`.
3. Prove decryption with the replacement identity.
4. Deploy and verify NASty decryption.
5. Only then remove the old recipient and run `sops updatekeys` again.

Never remove the last verified recovery recipient.

NASty SSH host-key rotation is intentionally **not** performed by this runbook. It requires a separate reviewed transition that stages old and new private key paths concurrently in sops-nix, proves decryption through the new path, switches SSH host identity, and only then removes the old recipient and private key. Stop rather than rotating the host key ad hoc.

---

## Do NOT

- Do not overwrite an existing operator age identity.
- Do not copy `/etc/ssh/ssh_host_ed25519_key` off NASty.
- Do not put secret values in `sops --set` arguments or exported environment variables.
- Do not run `cat`, `head`, `tail`, or an unfiltered decrypt command on the runtime file.
- Do not commit editor swap, backup, or plaintext files.
- Do not remove an old recipient until replacement decryption and deployment both succeed.
