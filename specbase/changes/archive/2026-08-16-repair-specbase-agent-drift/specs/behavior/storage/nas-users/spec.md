---
id: behavior.storage.nas-users
---

## Purpose

This pair governs the operator administration contract: key-based SSH access and passwordless root escalation on the deployed NAS.

## MODIFIED Requirements

### Requirement: operator admin user can administer over SSH without a password
**ID:** `operator-access`
The NAS configuration SHALL define an `operator` user in the `wheel` group with
an authorized SSH public key, and `wheel` SHALL be permitted to run `sudo`
without a password. The `operator` user SHALL be able to authenticate over SSH
using the authorized key and escalate to root without being prompted.

#### Scenario: operator user is declared
**ID:** `operator-declared`
- **WHEN** the `nas` configuration is evaluated
- **THEN** `users.users.operator` exists, is a normal user, and is in the
  `wheel` group
- **AND** `operator`'s authorized SSH keys include the declared ed25519 key

#### Scenario: wheel has passwordless sudo
**ID:** `wheel-passwordless-sudo`
- **WHEN** the `nas` configuration is evaluated
- **THEN** `security.sudo.wheelNeedsPassword` is `false`

#### Scenario: operator can SSH in and escalate
**ID:** `operator-ssh-sudo-runtime`
- **WHEN** the configuration is applied on the NAS
- **THEN** `ssh operator@10.10.10.11` succeeds with the authorized key (no
  password)
- **AND** `sudo whoami` returns `root` with no password prompt
