# User runbook: establish network secret operations

## Why you are needed

Automation must never generate, view, transmit, or retain your production decryption identity, NetBird PAT, or OPNsense API secret. You perform the custody and credential-creation steps locally after the repository tools and permanent operations runbook exist.

## Do not do this yet

Wait until Tasks 1.1–2.1 are complete and `docs/operations/network-secret-operations.md` has been reviewed. Do not paste any secret into chat, a task log, Git, shell history, or a command argument.

## When to act

### Task 2.2: create and back up the operator age identity

Using the flake-provided tools and the permanent runbook:

1. Create the age identity directly at the documented user-private path outside the repository.
2. Set directory/file permissions exactly as documented.
3. Derive and record only its public `age1...` recipient.
4. Make an independently protected recovery copy on encrypted storage or another approved secret store.
5. Do not put the private identity in SOPS, Git, the Nix store, or project evidence.

Stop if the proposed backup location is not independently protected.

### Task 2.3: approve the SOPS recipient policy

Review `.sops.yaml` and confirm that:

- the public recipient is yours
- the recovery recipient is expected
- the rule covers `secrets/network.yaml`
- there is one root policy rather than a nested competing policy

The first encryption/decryption exercise must use dummy values.

### Task 2.4: approve the OPNsense automation boundary

From the local OPNsense GUI, inspect the installed version and official plugin/API privilege names. Review the proposed least-privilege ACL list in the permanent runbook. Stop if the installed release cannot expose the required read-only status, package/plugin, NetBird settings/service, interface, firewall, backup, and reload operations through a bounded automation user.

Record only the version and ACL names. Do not create the key until this boundary is accepted.

### Task 2.5: create the production credentials

Create the credentials in their respective administrative interfaces:

1. Create a NetBird management PAT with the narrowest permissions that support the planned provider and setup-key API operations.
2. Create a dedicated North York OPNsense automation user and API key with only the ACLs accepted in Task 2.4.
3. Open `secrets/network.yaml` through `sops` and enter the remote credential values inside the editor.
4. Use the documented private-input helper to generate and insert the OpenTofu state-encryption passphrase without placing it in a command argument, terminal output, or plaintext file.
5. Save, close, and confirm the tracked file contains SOPS metadata and ciphertext only.

Do not first place values in a plaintext scratch file, clipboard manager, shell variable, or unencrypted editor buffer. Revoke and recreate a credential immediately if it is exposed.

### Task 4.4: perform the recovery drill

Temporarily move the primary local test identity aside and follow the documented recovery procedure using independently held material and dummy ciphertext. Restore normal custody afterward. Record only public fingerprints and pass/fail status.

### Task 5.1: authorize read-only authentication checks

Run or allow the bounded wrappers to make authentication/read-only status calls to NetBird and OPNsense. Confirm that output contains no credential values and no remote configuration changes.

### Credential rotation procedure

The initial proposal establishes and reviews the rotation procedure; do not rotate newly created production credentials merely to manufacture evidence unless the runbook explicitly uses a safe test credential. For a real future rotation, create and validate the replacement before revoking the predecessor.

## Stop conditions

Stop immediately if:

- plaintext appears in Git status, logs, terminal tracing, or process arguments
- a private age identity enters the repository
- the OPNsense account requires broader ACLs than documented
- a setup key is proposed for `secrets/network.yaml` or OpenTofu state
- the recovery copy cannot decrypt dummy ciphertext

## Evidence to record

Record only dates, public age recipients/fingerprints, non-secret credential identifiers, ACL names, commands with values redacted, and pass/fail results. Never capture tokens, API secrets, private identities, decrypted documents, or environment dumps.
