# Network credential bootstrap

Date: 2026-09-05

Result: PASS.

- NetBird service user: `Config Automation`.
- NetBird role: `Network Admin`.
- NetBird token identifier: `Infra Token`.
- NetBird token expiry: 2027-09-05.
- The token has an independently stored Bitwarden copy.
- The `svc-admin` OPNsense API credential was created after the approved ACL review.
- A unique OpenTofu state-encryption passphrase was generated directly for this use.
- `secrets/network.yaml` contains exactly the six selected fields as SOPS ciphertext for the declared operator recipient.
- No setup key, private age identity, OpenTofu state, or credential value is recorded in evidence.
- The operator confirmed direct encrypted entry and removal of transient credential material; no plaintext value was placed in repository commands or captured output.

## Read-only authentication

- NetBird provider authentication: PASS. The check read account settings through the `opentofu` SecretSpec scope and created no resource or persistent state.
- OPNsense authentication: PASS. The check read `api/netbird/status/status` through the `opnsense` SecretSpec scope with HTTP GET and Ansible check mode.
- OPNsense TLS verification used the pinned public certificate at `ansible/certificates/north-york-opnsense-web.pem`; its SHA-256 fingerprint is `6D:55:E3:80:0D:84:0C:CD:49:AD:F6:16:44:DB:39:42:E8:B4:7A:CC:EA:F0:7F:0F:A0:DD:7F:0A:E7:81:BA:29` and it expires on 2026-10-28.
- Both checks suppressed consumer output and made no remote changes.

This records credential custody, ciphertext structure, and bounded read-only authentication. It does not authorize configuration changes.
