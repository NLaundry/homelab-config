# Operator tools

Install Nix with flakes enabled, then run `nix develop`. The shared package list
is `nix/dev.nix`; `flake.lock` pins nixpkgs and therefore the tool versions.

| Tool | Purpose |
|---|---|
| Make | Repository commands in `Makefile` |
| Git | Version control |
| `nixos-rebuild` | Build and activate NixOS configurations |
| OpenSSH | Remote builds, deployment, and health checks |
| Ansible | Manage non-Nix hosts |
| OpenTofu | Network infrastructure plans and configuration |
| SOPS | Encrypt secret documents and decrypt them for consumers |
| age / age-keygen | Create and use encryption identities |
| Nano | Edit secrets through SOPS |
| jq / yq | Inspect JSON and YAML |
| Bats | Run shell tests |
| ShellCheck / shfmt | Check and format shell code |

On macOS, `ssh` is a small Nix-packaged adapter to `/usr/bin/ssh`. This avoids
local-network permission problems observed with Nix-packaged OpenSSH. Linux
uses nixpkgs OpenSSH directly. Live SMB checks also use macOS's `smbutil` and
`mount_smbfs`; the complete live suite requires a Mac.

The live verification app supplies its own runtime tools.
The Samba VM test supplies its NixOS driver and QEMU dependencies. Its execution
host needs Linux, Nix, SSH access, and usable KVM, not the full development shell.

Private age identities, recovery copies, decrypted credentials, and OpenTofu
state stay outside Git and the Nix store. Installing tools does not create or
configure these values. Follow the relevant runbook before using them.

Pi and the OpenSpec CLI are optional and installed separately. OpenSpec manages
planned changes under `openspec/`; it is not part of the Nix shell or normal
checks. See [the planning guide](openspec/README.md).
