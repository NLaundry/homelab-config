# Enforcement: operator admin user can administer over SSH without a password

Paired with `spec.md` (`behavior.storage.nas-users`). The declarative intent
(operator user declared, in wheel, key authorized, passwordless sudo) is proven
from the workstation by `nix eval` over the repo's flake. The runtime outcome
(operator can actually SSH in and escalate) genuinely requires the box, so it
is an honest `manual` binding.

```yaml
version: 1
spec: behavior.storage.nas-users
bindings:
  - id: operator-config-intent
    covers: [operator-access, operator-declared, wheel-passwordless-sudo]
    mechanism: command
    strength: automated
    status: active
    targets:
      - hosts/nas/default.nix
    run:
      command: nix
      args:
        - eval
        - --json
        - .#nixosConfigurations.nas.config.users.users.operator
      cwd: .
    limitations: >-
      Proves the operator user and wheel-sudo config are declared in the flake,
      not that the authorized key is the right one or that the box accepts it.

  - id: operator-ssh-sudo-runtime
    covers: [operator-ssh-sudo-runtime]
    mechanism: manual
    strength: manual
    status: active
    targets:
      - hosts/nas/default.nix
    procedure: >-
      From the workstation, run `ssh -i ~/.ssh/id_ed25519 operator@10.10.10.11
      'sudo whoami'` and confirm it prints `root` with no password prompt.
      Requires the box reachable over SSH.
    rationale: >-
      SSH-key authentication and sudo escalation are runtime outcomes of the
      applied system; no workstation-side check proves the box accepts the key.
    limitations: Confirms access at the time it is run, not continuously.
