# OPNsense operations

Run from the repository root. Install the pinned collection once:

```sh
nix develop
ansible-galaxy collection install -r ansible/requirements.yml -p .ansible/collections
export ANSIBLE_CONFIG="$PWD/ansible/ansible.cfg"
export SOPS_AGE_KEY_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt"
```

Use explicit inventory arguments. The configuration resolves collection and role
paths relative to `ansible/ansible.cfg`; SSH host verification remains enabled.
The OPNsense playbooks run locally and do not require root SSH access.

Current procedures: [DNS/DHCP](../docs/operations/opnsense-dns.md),
[NetBird routing](../docs/operations/netbird-routing.md), and
[native ACME](../docs/operations/opnsense-acme.md). Default runs compare only;
apply and reapply require explicit flags. Retired enrollment preparation and ISC
cutover flags cannot reset the commissioned router.

## Check configuration without live requests

```sh
for play in ansible/playbooks/*.yml; do
  ansible-playbook -i ansible/inventory.yml --syntax-check "$play"
done
make test-local
```

Local tests use dummy credentials and a loopback-only TLS fixture. They do not
verify the real router, the granted API privileges or working routing.

## Select verified management transport

`group_vars/all/opnsense.yml` declares the approved profiles. Credentials and
`OPNSENSE_URL` are delivered by the existing SecretSpec `opnsense` scope.

- `OPNSENSE_PROFILE=private` is the current default. It verifies
  `opnsense.ny.laundrylab.internal` with the public LaundryLab root.
- `OPNSENSE_PROFILE=legacy` is retained for explicit recovery with the matching
  old certificate selected; it verifies `opnsense.localdomain`.
- `OPNSENSE_URL` must match the selected hostname and port, with no path, query,
  fragment or embedded credentials. A mismatched URL stops before a request.

The scoped URL and default moved together after verified backups, matching saved
and served certificates, alternate-hostname inspection and repeated API adoption.
Broader browser, renewal and off-LAN acceptance remain open. Future transitions
must repeat these checks; a permission grant alone is not acceptance.

For local credential validation without an API request:

```sh
secretspec run --profile north_york --scope opnsense -- \
  ansible-playbook -i ansible/inventory.yml \
  ansible/playbooks/opnsense-credential-preflight.yml
```

Add `-e opnsense_auth_check=true` for the explicit read-only API and connected-peer
check. The connector Bats test reuses that same playbook instead of maintaining a
second TLS implementation. `OPNSENSE_VERIFY=1` selects that probe even when inputs
are missing, so missing credentials fail rather than skip.

## Recover without DNS

The DNS recovery transport uses the selected profile's fixed address while
retaining its hostname and trust checks. Profile selection is explicit and never
changes automatically after a TLS failure. First restore the matching GUI
certificate through independent management or console access if needed; retaining
a recovery profile does not make the router serve that old certificate.

Keep recovery certificates valid and retain the DNS-only recovery approvals in
the operating runbook. Do not disable TLS verification, restart ISC implicitly,
or expose credentials through verbose output or command arguments.
