#!/usr/bin/env bats

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  FLAKE_REF=${HOMELAB_FLAKE_REF:-"path:$ROOT"}
  ORDINARY_SHARES="$ROOT/nix/ordinary-smb-shares.txt"
  RUN_ID='run-20260817T000000Z-0123456789abcdef'
}

assert_audit_record() {
  local record=$1 expected_run_id=$2 principal client share operation status path extra
  IFS='|' read -r principal client share operation status path extra <<<"$record"
  [[ $principal == tester ]] || { printf 'audit principal missing: %s\n' "$record" >&2; return 1; }
  [[ $client =~ ^[0-9a-fA-F:.]+$ ]] || { printf 'audit client missing: %s\n' "$record" >&2; return 1; }
  [[ $share == 'homelab-verification$' ]] || { printf 'audit share missing: %s\n' "$record" >&2; return 1; }
  [[ $operation =~ ^(mkdirat|create_file|openat|write|pwrite|renameat|unlinkat)$ ]] || {
    printf 'audit operation is not selected: %s\n' "$record" >&2
    return 1
  }
  [[ $status == ok ]] || { printf 'audit mutation did not succeed: %s\n' "$record" >&2; return 1; }
  [[ $path == *"/$expected_run_id" || $path == *"/$expected_run_id/"* ]] || {
    printf 'audit path omits run identity: %s\n' "$record" >&2
    return 1
  }
  [[ -z ${extra:-} ]] || { printf 'audit record has unexpected fields: %s\n' "$record" >&2; return 1; }
}

@test "the hidden Samba endpoint is authenticated and path-confined" {
  local share
  share=$(nix eval --json \
    "$FLAKE_REF#nixosConfigurations.nas.config.services.samba.settings.\"homelab-verification$\"")

  jq -e '
    .path == "/var/lib/homelab-verification/smb/runs" and
    .browseable == "no" and .["guest ok"] == "no" and
    .["read only"] == "no" and .["valid users"] == "tester" and
    .["follow symlinks"] == "no" and .["wide links"] == "no" and
    (has("force user") | not)
  ' <<<"$share" >/dev/null
}

@test "every ordinary Samba share explicitly denies tester without changing guest semantics" {
  local settings expected actual
  settings=$(nix eval --json "$FLAKE_REF#nixosConfigurations.nas.config.services.samba.settings")
  expected=$(grep -Ev '^[[:space:]]*(#|$)' "$ORDINARY_SHARES" | jq -Rsc 'split("\n") | map(select(length > 0)) | sort')
  actual=$(jq -c '[keys[] | select(. != "global" and . != "homelab-verification$")] | sort' <<<"$settings")
  [ "$actual" = "$expected" ]

  jq -e --argjson ordinary "$expected" '
    . as $settings |
    all($ordinary[]; . as $name |
      $settings[$name]["invalid users"] == "tester" and
      $settings[$name]["guest ok"] == "yes" and
      $settings[$name]["read only"] == "no" and
      $settings[$name]["force user"] == "operator")
  ' <<<"$settings" >/dev/null
}

@test "verification storage has finite capacity and root-controlled initialization" {
  local filesystem initializer
  filesystem=$(nix eval --json \
    "$FLAKE_REF#nixosConfigurations.nas.config.fileSystems.\"/var/lib/homelab-verification/smb\"")
  initializer=$(nix eval --raw \
    "$FLAKE_REF#nixosConfigurations.nas.config.systemd.services.homelab-verification-state.script")

  jq -e '
    .fsType == "tmpfs" and .device == "tmpfs" and
    (.options | index("size=64M") != null) and
    (.options | index("nr_inodes=4096") != null) and
    (.options | index("uid=0") != null) and
    (.options | index("gid=980") != null) and
    (.options | index("mode=0750") != null) and
    (.options | index("nodev") != null) and
    (.options | index("noexec") != null) and
    (.options | index("nosuid") != null)
  ' <<<"$filesystem" >/dev/null
  [[ $initializer == *"-o operator -g verification -m 0750 /var/lib/homelab-verification/smb"* ]]
  [[ $initializer == *"-o operator -g verification -m 0730 /var/lib/homelab-verification/smb/runs"* ]]
}

@test "the selected audit configuration records mutation identity and path outside tester control" {
  local share tester
  share=$(nix eval --json \
    "$FLAKE_REF#nixosConfigurations.nas.config.services.samba.settings.\"homelab-verification$\"")
  tester=$(nix eval --json "$FLAKE_REF#nixosConfigurations.nas.config.users.users.tester")

  jq -e '
    .["vfs objects"] == "full_audit fruit streams_xattr" and
    .["full_audit:prefix"] == "%u|%I|homelab-verification$" and
    .["full_audit:success"] == "mkdirat create_file openat write pwrite renameat unlinkat" and
    .["full_audit:failure"] == "none" and
    .["full_audit:facility"] == "LOCAL5" and
    .["full_audit:priority"] == "NOTICE" and
    .["full_audit:syslog"] == "true"
  ' <<<"$share" >/dev/null
  jq -e '.extraGroups | index("systemd-journal") == null and index("wheel") == null' \
    <<<"$tester" >/dev/null
}

@test "a complete audit fixture preserves principal, client, share, operation, and run path" {
  run assert_audit_record \
    "tester|10.10.10.42|homelab-verification$|create_file|ok|/var/lib/homelab-verification/smb/runs/$RUN_ID/file" \
    "$RUN_ID"
  [ "$status" -eq 0 ]
}

@test "incomplete or wrongly attributed audit fixtures are rejected" {
  local fixture
  for fixture in \
    "operator|10.10.10.42|homelab-verification$|write|ok|/runs/$RUN_ID/file" \
    "tester||homelab-verification$|write|ok|/runs/$RUN_ID/file" \
    "tester|10.10.10.42|mediaBin|write|ok|/runs/$RUN_ID/file" \
    "tester|10.10.10.42|homelab-verification$|read|ok|/runs/$RUN_ID/file" \
    "tester|10.10.10.42|homelab-verification$|write|ok|/runs/another-run/file" \
    "tester|10.10.10.42|homelab-verification$|write|ok|/runs/$RUN_ID-impostor/file"; do
    run assert_audit_record "$fixture" "$RUN_ID"
    [ "$status" -ne 0 ]
  done
}
