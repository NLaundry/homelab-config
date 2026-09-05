#!/usr/bin/env bats
# Run API tests separately under their matching SecretSpec scopes.

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
  [ -n "${OPNSENSE_API_KEY:-}" ] || skip "Run under SecretSpec scope opnsense"
  export CONNECTOR_CA="$BATS_TEST_DIRNAME/../../ansible/certificates/north-york-opnsense-web.pem"
  run python3 - <<'PY'
import base64, json, os, ssl, urllib.request
try:
    auth = base64.b64encode((os.environ['OPNSENSE_API_KEY'] + ':' + os.environ['OPNSENSE_API_SECRET']).encode()).decode()
    request = urllib.request.Request(os.environ['OPNSENSE_URL'].rstrip('/') + '/api/netbird/status/status',
        headers={'Authorization': 'Basic ' + auth})
    context = ssl.create_default_context(cafile=os.environ['CONNECTOR_CA'])
    with urllib.request.urlopen(request, context=context, timeout=10) as response:
        result = json.load(response)
    assert result['management']['connected'] is True
except Exception:
    raise SystemExit('FAIL: OPNsense authenticated read or NetBird disconnected')
print('PASS: OPNsense API and NetBird connection')
PY
  [ "$status" -eq 0 ]
}

@test "North York routed service connection" {
  [ "${OFF_LAN_TEST:-}" = 1 ] || skip "Run off the North York LAN with OFF_LAN_TEST=1"
  [ -n "${ROUTED_TARGET:-}" ] && [ -n "${ROUTED_PORT:-}" ]
  # Require the expected NetBird interface, not merely a working local-LAN route.
  [ -n "${NETBIRD_INTERFACE:-}" ]
  if [ "$(uname -s)" = Darwin ]; then
    run /sbin/route -n get "$ROUTED_TARGET"
    [ "$status" -eq 0 ]
    actual=$(printf '%s\n' "$output" | awk '/interface:/ {print $2}')
  else
    run ip route get "$ROUTED_TARGET"
    [ "$status" -eq 0 ]
    actual=$(printf '%s\n' "$output" | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}')
  fi
  [ "$actual" = "$NETBIRD_INTERFACE" ]
  run python3 - <<'PY'
import os, socket
try:
    with socket.create_connection((os.environ['ROUTED_TARGET'], int(os.environ['ROUTED_PORT'])), timeout=5):
        pass
except Exception:
    raise SystemExit('FAIL: North York service connection')
print('PASS: North York service connection')
PY
  [ "$status" -eq 0 ]
}
