#!/usr/bin/env bats
# Live router TLS probe: the OPNsense WebGUI must serve the certificate
# our CA issued for exactly the router name, inside its 7-day renewal
# window. Detects silent renewal failure before the cert expires.
# Read-only; no state changes and no -k shortcuts.

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  ROUTER_HOST=${HOMELAB_ROUTER_HOST:-opnsense.ny.laundrylab.internal}
  ROOT_CERT="$ROOT/certificates/laundrylab-root-ca.crt"
  PINNED_INTERMEDIATE="$ROOT/certificates/laundrylab-intermediate-ca.crt"
  capture_leaf() {
    echo | openssl s_client -connect "$ROUTER_HOST:443" -servername "$ROUTER_HOST" \
      -showcerts -CAfile "$ROOT_CERT" 2>/dev/null \
      | awk '/BEGIN CERTIFICATE/{n++} n==1' > "$BATS_TEST_TMPDIR/leaf.pem"
    [ -s "$BATS_TEST_TMPDIR/leaf.pem" ]
  }
}

@test "the router serves a certificate issued by our CA for its own name" {
  capture_leaf || return 1
  run openssl verify -CAfile "$ROOT_CERT" -untrusted "$PINNED_INTERMEDIATE" "$BATS_TEST_TMPDIR/leaf.pem"
  [ "$status" -eq 0 ]
  run openssl x509 -in "$BATS_TEST_TMPDIR/leaf.pem" -noout -subject -issuer
  [ "$status" -eq 0 ]
  [[ "$output" == *"CN=$ROUTER_HOST"* ]]
  [[ "$output" == *"CN=LaundryLab Intermediate CA"* ]]
  dns_count=$(openssl x509 -in "$BATS_TEST_TMPDIR/leaf.pem" -noout -text \
    | grep -A2 'Subject Alternative Name' | grep -o 'DNS:' | wc -l | tr -d ' ')
  [ "$dns_count" -eq 1 ]
  openssl x509 -in "$BATS_TEST_TMPDIR/leaf.pem" -noout -text \
    | grep -A2 'Subject Alternative Name' | grep -q "DNS:$ROUTER_HOST"
}

@test "the router certificate is inside its daily 7-day renewal window" {
  capture_leaf || return 1
  # Renewal is daily with 7-day validity: healthy leaves have more than
  # 24 hours left and never more than 8 days.
  run openssl x509 -in "$BATS_TEST_TMPDIR/leaf.pem" -checkend 86400
  [ "$status" -eq 0 ]
  run openssl x509 -in "$BATS_TEST_TMPDIR/leaf.pem" -checkend 691200
  [ "$status" -ne 0 ]
}
