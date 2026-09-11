#!/usr/bin/env bats
# Read-only private-PKI probes: normal client trust, router certificate, and CA health.

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  ROUTER_HOST=${HOMELAB_ROUTER_HOST:-opnsense.ny.laundrylab.internal}
  CA_HOST=${HOMELAB_CA_HOST:-ca.laundrylab.internal}
  NAS_JUMP=${HOMELAB_DEPLOYMENT_TARGET:-operator@10.10.10.11}
  ROOT_CERT="$ROOT/infra/certificates/laundrylab-root-ca.crt"
  PINNED_INTERMEDIATE="$ROOT/infra/certificates/laundrylab-intermediate-ca.crt"
  SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=5)
  CHAIN="$BATS_TEST_TMPDIR/chain.pem"
  capture_leaf() {
    echo | openssl s_client -connect "$ROUTER_HOST:443" -servername "$ROUTER_HOST" \
      -showcerts -CAfile "$ROOT_CERT" 2>/dev/null \
      | awk '/BEGIN CERTIFICATE/{n++} n==1' > "$BATS_TEST_TMPDIR/leaf.pem"
    [ -s "$BATS_TEST_TMPDIR/leaf.pem" ]
  }
}

health_direct() {
  curl -sS --fail --max-time 10 --cacert "$ROOT_CERT" "https://$CA_HOST/health"
}

health_via_nas() {
  local remote_tmp
  remote_tmp=$(ssh "${SSH_OPTS[@]}" "$NAS_JUMP" 'mktemp /tmp/step-ca-root.XXXXXX') || return 1
  if ! ssh "${SSH_OPTS[@]}" "$NAS_JUMP" "cat > '$remote_tmp'" < "$ROOT_CERT"; then
    ssh "${SSH_OPTS[@]}" "$NAS_JUMP" "rm -f '$remote_tmp'" >/dev/null 2>&1
    return 1
  fi
  ssh "${SSH_OPTS[@]}" "$NAS_JUMP" \
    "curl -sS --fail --max-time 10 --cacert '$remote_tmp' https://$CA_HOST/health && rm -f '$remote_tmp'"
}

fetch_chain_direct() {
  echo | openssl s_client -connect "$CA_HOST:443" -servername "$CA_HOST" \
    -showcerts -CAfile "$ROOT_CERT" 2>/dev/null \
    | awk '/BEGIN CERTIFICATE/{n++} n>=1' > "$CHAIN"
  [ "$(grep -c 'BEGIN CERTIFICATE' "$CHAIN" 2>/dev/null)" -ge 2 ]
}

fetch_chain_via_nas() {
  ssh "${SSH_OPTS[@]}" "$NAS_JUMP" \
    "curl -sS --max-time 10 --write-out '%{certs}' -o /dev/null https://$CA_HOST/" \
    > "$CHAIN" 2>/dev/null
  [ "$(grep -c 'BEGIN CERTIFICATE' "$CHAIN" 2>/dev/null)" -ge 2 ]
}

chain_cert() {
  awk -v want="$1" '/BEGIN CERTIFICATE/{n++} n==want' "$CHAIN"
}

@test "OPNsense HTTPS works with the selected curl client's normal trust" {
  [ "${HTTPS_VERIFY:-}" = 1 ] || skip "Set HTTPS_VERIFY=1 and the explicit approved HTTPS_URL"
  [ "${HTTPS_URL:-}" = 'https://opnsense.ny.laundrylab.internal/' ] || {
    printf 'HTTPS_URL must be the exact approved OPNsense HTTPS origin with trailing slash\n' >&2
    return 1
  }
  run command curl --disable --noproxy '*' --proto '=https' \
    --connect-timeout 5 --max-time 15 --silent --show-error --fail \
    --output /dev/null --write-out '%{http_code}' "$HTTPS_URL"
  [ "$status" -eq 0 ] || return 1
  [[ "$output" =~ ^2[0-9][0-9]$ ]]
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
  run openssl x509 -in "$BATS_TEST_TMPDIR/leaf.pem" -checkend 86400
  [ "$status" -eq 0 ]
  run openssl x509 -in "$BATS_TEST_TMPDIR/leaf.pem" -checkend 691200
  [ "$status" -ne 0 ]
}

@test "the CA answers /health under the published root trust" {
  if run health_direct && [[ "$output" == *'"status":"ok"'* ]]; then
    return 0
  fi
  run health_via_nas
  [ "$status" -eq 0 ]
  [[ "$output" == *'"status":"ok"'* ]]
}

@test "the CA still serves the commissioned intermediate" {
  if ! fetch_chain_direct; then
    fetch_chain_via_nas || return 1
  fi
  chain_cert 2 > "$BATS_TEST_TMPDIR/intermediate.pem"
  chain_cert 1 > "$BATS_TEST_TMPDIR/leaf.pem"
  [ -s "$BATS_TEST_TMPDIR/intermediate.pem" ]
  [ -s "$BATS_TEST_TMPDIR/leaf.pem" ]
  expected=$(openssl x509 -in "$PINNED_INTERMEDIATE" -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2)
  actual=$(openssl x509 -in "$BATS_TEST_TMPDIR/intermediate.pem" -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2)
  [ -n "$expected" ] && [ "$actual" = "$expected" ]
  run openssl verify -CAfile "$ROOT_CERT" -untrusted "$BATS_TEST_TMPDIR/intermediate.pem" "$BATS_TEST_TMPDIR/leaf.pem"
  [ "$status" -eq 0 ]
}
