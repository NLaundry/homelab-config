#!/usr/bin/env bats
# Live step-ca probe: the deployed CA must be healthy under the repo's
# published root trust, and must still be the commissioned intermediate.
# Read-only; no state changes, no -k shortcuts, and TLS trust is verified
# under the published root on every path. Prefers the direct client path;
# falls back to the verified NAS jump when the operator machine cannot
# route to the guest VM (Wi-Fi/middlebox quirks), without weakening checks.

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  CA_HOST=${HOMELAB_CA_HOST:-ca.laundrylab.internal}
  NAS_JUMP=${HOMELAB_DEPLOYMENT_TARGET:-operator@10.10.10.11}
  ROOT_CERT="$ROOT/certificates/laundrylab-root-ca.crt"
  PINNED_INTERMEDIATE="$ROOT/certificates/laundrylab-intermediate-ca.crt"
  SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=5)
  CHAIN="$BATS_TEST_TMPDIR/chain.pem"
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
  [ -s "$CHAIN" ]
}

fetch_chain_via_nas() {
  ssh "${SSH_OPTS[@]}" "$NAS_JUMP" \
    "curl -sS --max-time 10 --write-out '%{certs}' -o /dev/null https://$CA_HOST/" \
    > "$CHAIN" 2>/dev/null
  [ "$(grep -c 'BEGIN CERTIFICATE' "$CHAIN" 2>/dev/null)" -ge 2 ]
}

chain_cert() { # $1 = 1-based position in the served chain
  awk -v want="$1" '/BEGIN CERTIFICATE/{n++} n==want' "$CHAIN"
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
