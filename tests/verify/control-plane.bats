#!/usr/bin/env bats
# Read-only control-plane probes for NetBird and OPNsense.

@test "NetBird API connection" {
  [ -n "${NB_PAT:-}" ] || skip "Run under SecretSpec scope opentofu"
  run bash -c 'curl --disable --noproxy "*" --proto "=https" \
    --connect-timeout 5 --max-time 15 --silent --show-error --fail \
    --config - <<EOF
url = "${NB_MANAGEMENT_URL%/}/api/networks"
header = "Authorization: Token ${NB_PAT}"
EOF'
  [ "$status" -eq 0 ]
  [[ "$output" == *'North York'* ]]
}

@test "OPNsense API connection" {
  if [ "${OPNSENSE_VERIFY:-}" != 1 ] && [ -z "${OPNSENSE_API_KEY:-}" ]; then
    skip "Run under SecretSpec scope opnsense, or select OPNSENSE_VERIFY=1"
  fi
  [ -n "${OPNSENSE_URL:-}" ]
  [ -n "${OPNSENSE_API_KEY:-}" ]
  [ -n "${OPNSENSE_API_SECRET:-}" ]

  run bash -c 'curl --disable --noproxy "*" --proto "=https" \
    --connect-timeout 5 --max-time 15 --silent --show-error --fail \
    --config - <<EOF
url = "${OPNSENSE_URL%/}/api/netbird/status/status"
user = "${OPNSENSE_API_KEY}:${OPNSENSE_API_SECRET}"
EOF'
  [ "$status" -eq 0 ]
}
