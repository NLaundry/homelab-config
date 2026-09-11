#!/usr/bin/env bats
# Read-only control-plane probes for NetBird and OPNsense.

@test "NetBird API connection" {
  [ -n "${NB_PAT:-}" ] || skip "Run under SecretSpec scope opentofu"
  run python3 - <<'PY'
import json, os, urllib.request
try:
    request = urllib.request.Request(os.environ['NB_MANAGEMENT_URL'].rstrip('/') + '/api/networks',
        headers={'Authorization': 'Token ' + os.environ['NB_PAT']})
    with urllib.request.urlopen(request, timeout=10) as response:
        networks = json.load(response)
    assert len([n for n in networks if n.get('name') == 'North York']) == 1
except Exception:
    raise SystemExit('FAIL: NetBird authenticated read')
print('PASS: NetBird authenticated read')
PY
  [ "$status" -eq 0 ]
}

@test "OPNsense API connection" {
  if [ "${OPNSENSE_VERIFY:-}" != 1 ] && [ -z "${OPNSENSE_API_KEY:-}" ]; then
    skip "Run under SecretSpec scope opnsense, or select OPNSENSE_VERIFY=1"
  fi
  local root="${HOMELAB_ROOT:-$BATS_TEST_DIRNAME/../..}"
  # Reuse the same input and TLS checks as configuration runs.
  run env ANSIBLE_CONFIG="$root/ansible/ansible.cfg" \
    ansible-playbook -i "$root/ansible/inventory.yml" \
    "$root/ansible/playbooks/opnsense-credential-preflight.yml" \
    -e opnsense_auth_check=true
  [ "$status" -eq 0 ]
}
