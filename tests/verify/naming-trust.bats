#!/usr/bin/env bats
# Read-only probes: independent DNS_VERIFY=1 and HTTPS_VERIFY=1 opt-ins.

valid_ipv4() {
  local address=$1 octet
  local -a octets
  [[ "$address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  IFS=. read -r -a octets <<< "$address"
  for octet in "${octets[@]}"; do
    # Reject ambiguous leading zeros as well as out-of-range octets.
    [[ "$octet" =~ ^(0|[1-9][0-9]{0,2})$ ]] || return 1
    (( octet <= 255 )) || return 1
  done
}

valid_private_fqdn() {
  local name label
  local -a labels
  [[ "$1" =~ ^[a-zA-Z0-9.-]+$ ]] || return 1
  name=$(printf '%s' "${1%.}" | tr '[:upper:]' '[:lower:]')
  [[ ${#name} -le 253 && "$name" == *.laundrylab.internal && "$name" != *..* ]] || return 1
  IFS=. read -r -a labels <<< "$name"
  for label in "${labels[@]}"; do
    [[ "$label" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]] || return 1
  done
}

require_dns_context() {
  [ "${DNS_VERIFY:-}" = 1 ] || skip "Set DNS_VERIFY=1 with explicit DNS targets and expected addresses"
  local variable
  # Validate the entire context before either test can invoke dig.
  for variable in DNS_SERVER DNS_SITE_ADDRESS DNS_SHARED_ADDRESS; do
    valid_ipv4 "${!variable:-}" || {
      printf 'Invalid or missing IPv4 input: %s\n' "$variable" >&2
      return 1
    }
  done
  for variable in DNS_SITE_FQDN DNS_SHARED_FQDN; do
    valid_private_fqdn "${!variable:-}" || {
      printf 'Invalid or missing laundrylab.internal FQDN: %s\n' "$variable" >&2
      return 1
    }
  done
}

assert_dns_answer() {
  local fqdn=$1 expected=$2 transport=$3
  # Ignore ~/.digrc; +ignore prevents a truncated UDP response retrying via TCP.
  run command dig -r "@$DNS_SERVER" "$fqdn" A "$transport" +ignore \
    +time=2 +tries=1 +noall +comments +answer
  [ "$status" -eq 0 ] || return 1
  printf '%s\n' "$output" | awk -v expected="$expected" '
    /^;; ->>HEADER<<-/ {
      header = 1
      if ($0 !~ /status: NOERROR,/) bad = 1
    }
    $0 !~ /^;/ && NF == 5 && $3 == "IN" && $4 == "A" {
      answers++
      if ($5 != expected) bad = 1
    }
    END {
      if (!header || !answers || bad) {
        print "Expected NOERROR and A answers matching " expected > "/dev/stderr"
        exit 1
      }
    }
  '
}

@test "Site and shared DNS A answers match over UDP" {
  require_dns_context
  assert_dns_answer "$DNS_SITE_FQDN" "$DNS_SITE_ADDRESS" +notcp
  assert_dns_answer "$DNS_SHARED_FQDN" "$DNS_SHARED_ADDRESS" +notcp
}

@test "Site DNS A answer matches over TCP" {
  require_dns_context
  assert_dns_answer "$DNS_SITE_FQDN" "$DNS_SITE_ADDRESS" +tcp
}

@test "OPNsense HTTPS works with the selected curl client's normal trust" {
  [ "${HTTPS_VERIFY:-}" = 1 ] || skip "Set HTTPS_VERIFY=1 and the explicit approved HTTPS_URL"
  [ "${HTTPS_URL:-}" = 'https://opnsense.ny.laundrylab.internal/' ] || {
    printf 'HTTPS_URL must be the exact approved OPNsense HTTPS origin with trailing slash\n' >&2
    return 1
  }
  # Ignore curlrc, do not follow redirects, and use this curl build's normal
  # trust store. No credentials, issuance, explicit CA override or insecure mode.
  # This is not evidence of browser/Keychain trust or an off-LAN path by itself.
  run command curl --disable --noproxy '*' --proto '=https' \
    --connect-timeout 5 --max-time 15 --silent --show-error --fail \
    --output /dev/null --write-out '%{http_code}' "$HTTPS_URL"
  [ "$status" -eq 0 ] || return 1
  [[ "$output" =~ ^2[0-9][0-9]$ ]]
}
