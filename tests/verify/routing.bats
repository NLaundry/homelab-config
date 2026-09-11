#!/usr/bin/env bats
# Opt-in off-LAN routed-service probe. Read-only; target and interface are explicit.

@test "North York routed service uses the NetBird path" {
  [ "${OFF_LAN_VERIFY:-}" = 1 ] || skip "Set OFF_LAN_VERIFY=1 with an explicit routed target"
  [ -n "${ROUTED_TARGET:-}" ]
  [ -n "${ROUTED_PORT:-}" ]
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

  run python3 - "$ROUTED_TARGET" "$ROUTED_PORT" <<'PY'
import socket
import sys

try:
    with socket.create_connection((sys.argv[1], int(sys.argv[2])), timeout=5):
        pass
except Exception as exc:
    raise SystemExit(f"FAIL: routed service connection: {exc}")
print("PASS: routed service connection")
PY
  [ "$status" -eq 0 ]
}
