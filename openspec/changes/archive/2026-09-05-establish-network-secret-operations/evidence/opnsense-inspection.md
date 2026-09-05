# OPNsense compatibility and ACL inspection

Date: 2026-09-05

Status: PASS.

GUI inspection recorded:

- Installed OPNsense version: `26.7.3`.
- The official `os-netbird` plugin is installed.
- The local group `netbird-automation` contains exactly these privileges:
  - `VPN: NetBird`
  - `Interfaces: Assign network ports`
  - `Firewall: Alias: Edit`
  - `Firewall: Rules [new]`
- The local automation user is `svc-admin`, with scrambled password login and membership only in `netbird-automation`.
- No direct user privileges, shell access, SSH keys, `admins`, `All pages`, firmware, or configuration-backup privileges were assigned.

Official source inspection confirmed that `VPN: NetBird` covers `ui/netbird/*` and `api/netbird/*`, while interface assignment and firewall APIs remain separately bounded. Source revisions inspected:

- `opnsense/plugins`: `31cc1ea4a2f439d81fc3375045b4121c92ed74c1`
- `opnsense/core`: `b33d23ee9a71684d35be697575ee2aa89a26fc5e`

No API key was generated during ACL discovery.
