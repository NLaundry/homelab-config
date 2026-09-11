# OPNsense operations

Run from the repository root. Install the pinned collection once:

```sh
nix develop
ansible-galaxy collection install -r infra/ansible/requirements.yml -p .ansible/collections
```

The dev shell sets `ANSIBLE_CONFIG` to `infra/ansible/ansible.cfg` and selects the
standard SOPS age key path automatically.

The playbooks run locally against the OPNsense API. They configure state only;
acceptance checks live in `tests/verify` and are run with `make verify`.

## Routine configuration

Routine runs are idempotent and do not enroll peers, issue an initial
certificate, or switch resolver ownership:

```sh
secretspec run --profile north_york --scope opnsense -- \
  ansible-playbook -i infra/ansible/inventory.yml infra/ansible/playbooks/opnsense-dns.yml

secretspec run --profile north_york --scope opnsense -- \
  ansible-playbook -i infra/ansible/inventory.yml infra/ansible/playbooks/opnsense-netbird-routing.yml

secretspec run --profile north_york --scope opnsense -- \
  ansible-playbook -i infra/ansible/inventory.yml infra/ansible/playbooks/opnsense-acme.yml
```

Check syntax before applying:

```sh
for play in infra/ansible/playbooks/*.yml; do
  ansible-playbook -i infra/ansible/inventory.yml --syntax-check "$play"
done
```

## One-time bootstrap

Bootstrap is explicit and should be run only when commissioning the related
service:

```sh
# Dnsmasq takes ownership from Unbound.
ansible-playbook -i infra/ansible/inventory.yml \
  infra/ansible/playbooks/opnsense-dns-bootstrap.yml

# The setup key is supplied out-of-band and is never logged.
export NETBIRD_SETUP_KEY='...'
ansible-playbook -i infra/ansible/inventory.yml \
  infra/ansible/playbooks/opnsense-netbird-enrollment.yml

# The internal step-ca directory is used for the first issuance.
ansible-playbook -i infra/ansible/inventory.yml \
  infra/ansible/playbooks/opnsense-acme-bootstrap.yml
```

The NetBird management URL comes from `NB_MANAGEMENT_URL` when supplied by
SecretSpec; otherwise the role default is the public NetBird endpoint. The
setup key must be supplied separately for the enrollment bootstrap.

## Transport and verification

`group_vars/all/opnsense.yml` declares the approved URL profiles. Credentials
and `OPNSENSE_URL` are delivered by the existing SecretSpec `opnsense` scope.
The selected URL must match its profile hostname and port and must not contain
a path, query, fragment, or embedded credentials.

After a change, run the relevant acceptance probes:

```sh
make verify VERIFY_ARGS=tests/verify/dns.bats
make verify VERIFY_ARGS=tests/verify/pki.bats
make verify VERIFY_ARGS=tests/verify/control-plane.bats
OFF_LAN_VERIFY=1 ROUTED_TARGET=... ROUTED_PORT=... \
  NETBIRD_INTERFACE=... make verify VERIFY_ARGS=tests/verify/routing.bats
```

The routing probe is opt-in because it needs a real off-LAN target. DHCP
client behavior remains a live-network concern rather than an Ansible task.
