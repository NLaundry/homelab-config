#!/usr/bin/env bats
# Read-only DNS probes. Expected names and addresses come from estate.yaml.

valid_ipv4() {
  local address=$1 octet
  local -a octets
  [[ "$address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  IFS=. read -r -a octets <<< "$address"
  for octet in "${octets[@]}"; do
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
  for variable in DNS_SERVER DNS_NAS_ADDRESS DNS_ROUTER_ADDRESS DNS_CA_ADDRESS; do
    valid_ipv4 "${!variable:-}" || {
      printf 'Invalid or missing IPv4 input: %s\n' "$variable" >&2
      return 1
    }
  done
  for variable in DNS_NAS_FQDN DNS_ROUTER_FQDN DNS_CA_FQDN; do
    valid_private_fqdn "${!variable:-}" || {
      printf 'Invalid or missing laundrylab.internal FQDN: %s\n' "$variable" >&2
      return 1
    }
  done
}

assert_dns_answer() {
  local fqdn=$1 expected=$2 transport=$3
  run command dig -r "@$DNS_SERVER" "$fqdn" A "$transport" +ignore \
    +time=2 +tries=1 +noall +comments +answer
  [ "$status" -eq 0 ] || return 1
  printf '%s\n' "$output" | awk -v expected="$expected" '
    /^;; ->>HEADER<</ {
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

assert_core_dns_answers() {
  local transport=$1
  assert_dns_answer "$DNS_NAS_FQDN" "$DNS_NAS_ADDRESS" "$transport"
  assert_dns_answer "$DNS_ROUTER_FQDN" "$DNS_ROUTER_ADDRESS" "$transport"
  assert_dns_answer "$DNS_CA_FQDN" "$DNS_CA_ADDRESS" "$transport"
}

@test "Core DNS A answers match estate addresses over UDP" {
  require_dns_context
  assert_core_dns_answers +notcp
}

@test "Core DNS A answers match estate addresses over TCP" {
  require_dns_context
  assert_core_dns_answers +tcp
}
