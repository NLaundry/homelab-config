#!/usr/bin/env bats

# shellcheck source=tests/verify/lib/run-namespace.sh
source "$BATS_TEST_DIRNAME/../verify/lib/run-namespace.sh"

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  FLAKE_REF=${HOMELAB_FLAKE_REF:-"path:$ROOT"}
  ORDINARY_SHARES="$ROOT/nix/ordinary-smb-shares.txt"
  WORKDIR=$(mktemp -d)
  VERIFICATION_ROOT="$WORKDIR/root"
  mkdir "$VERIFICATION_ROOT"
  export VERIFICATION_RUN_ID='run-20260817T000000Z-0123456789abcdef'
}

teardown() {
  rm -rf "$WORKDIR"
}

@test "the tester identity is stable, non-login, and unprivileged" {
  local user operator trusted_users
  user=$(nix eval --json "$FLAKE_REF#nixosConfigurations.nas.config.users.users.tester")
  operator=$(nix eval --json "$FLAKE_REF#nixosConfigurations.nas.config.users.users.operator")
  trusted_users=$(nix eval --json "$FLAKE_REF#nixosConfigurations.nas.config.nix.settings.trusted-users")

  jq -e '
    .uid == 980 and .isSystemUser == true and .group == "verification" and
    .createHome == false and .hashedPassword == "!" and
    .extraGroups == [] and .openssh.authorizedKeys.keys == [] and
    (.shell | endswith("-shadow-4.19.4"))
  ' <<<"$user" >/dev/null
  [ "$(jq -r .uid <<<"$user")" != "$(jq -r .uid <<<"$operator")" ]
  run jq -e 'index("tester") != null' <<<"$trusted_users"
  [ "$status" -ne 0 ]
}

@test "every ordinary share denies tester while the hidden endpoint never forces operator" {
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
      $settings[$name]["force user"] == "operator") and
    $settings["homelab-verification$"]["valid users"] == "tester" and
    ($settings["homelab-verification$"] | has("force user") | not)
  ' <<<"$settings" >/dev/null
}

@test "verification state has independent ceilings and mount-ordered initialization" {
  local filesystem after requires before required_by wanted_by script
  filesystem=$(nix eval --json \
    "$FLAKE_REF#nixosConfigurations.nas.config.fileSystems.\"/var/lib/homelab-verification/smb\"")
  after=$(nix eval --json \
    "$FLAKE_REF#nixosConfigurations.nas.config.systemd.services.homelab-verification-state.after")
  requires=$(nix eval --json \
    "$FLAKE_REF#nixosConfigurations.nas.config.systemd.services.homelab-verification-state.requires")
  before=$(nix eval --json \
    "$FLAKE_REF#nixosConfigurations.nas.config.systemd.services.homelab-verification-state.before")
  required_by=$(nix eval --json \
    "$FLAKE_REF#nixosConfigurations.nas.config.systemd.services.homelab-verification-state.requiredBy")
  wanted_by=$(nix eval --json \
    "$FLAKE_REF#nixosConfigurations.nas.config.systemd.services.homelab-verification-state.wantedBy")
  script=$(nix eval --raw \
    "$FLAKE_REF#nixosConfigurations.nas.config.systemd.services.homelab-verification-state.script")

  jq -e '
    .device == "tmpfs" and .fsType == "tmpfs" and
    (.options | index("size=64M") != null) and
    (.options | index("nr_inodes=4096") != null) and
    (.options | index("nodev") != null) and
    (.options | index("noexec") != null) and
    (.options | index("nosuid") != null)
  ' <<<"$filesystem" >/dev/null
  jq -e 'index("var-lib-homelab\\x2dverification-smb.mount") != null' <<<"$after" >/dev/null
  jq -e 'index("var-lib-homelab\\x2dverification-smb.mount") != null' <<<"$requires" >/dev/null
  jq -e 'index("samba-smbd.service") != null' <<<"$before" >/dev/null
  jq -e 'index("samba-smbd.service") != null' <<<"$required_by" >/dev/null
  jq -e 'index("multi-user.target") != null' <<<"$wanted_by" >/dev/null
  [[ $script == *"-m 0750 /var/lib/homelab-verification/smb"* ]]
  [[ $script == *"-m 0730 /var/lib/homelab-verification/smb/runs"* ]]
}

@test "a valid run namespace is created exclusively and removed exactly" {
  run verification_create_namespace "$VERIFICATION_ROOT" "$VERIFICATION_RUN_ID"
  [ "$status" -eq 0 ]
  [ -d "$VERIFICATION_ROOT/$VERIFICATION_RUN_ID" ]

  run verification_create_namespace "$VERIFICATION_ROOT" "$VERIFICATION_RUN_ID"
  [ "$status" -ne 0 ]
  [[ $output == *"already exists or cannot be created"* ]]

  run verification_remove_namespace "$VERIFICATION_ROOT" "$VERIFICATION_RUN_ID"
  [ "$status" -eq 0 ]
  [ ! -e "$VERIFICATION_ROOT/$VERIFICATION_RUN_ID" ]
}

@test "traversal, symlink roots, and symlink run targets are rejected" {
  local invalid symlink_root
  for invalid in '../outside' '/tmp/outside' 'run-short' \
    'run-20260817T000000Z-0123456789abcdef/child'; do
    run verification_namespace_path "$VERIFICATION_ROOT" "$invalid"
    [ "$status" -ne 0 ]
  done

  symlink_root="$WORKDIR/root-link"
  ln -s "$VERIFICATION_ROOT" "$symlink_root"
  run verification_namespace_path "$symlink_root" "$VERIFICATION_RUN_ID"
  [ "$status" -ne 0 ]

  ln -s "$WORKDIR" "$VERIFICATION_ROOT/$VERIFICATION_RUN_ID"
  run verification_remove_namespace "$VERIFICATION_ROOT" "$VERIFICATION_RUN_ID"
  [ "$status" -ne 0 ]
  [ -L "$VERIFICATION_ROOT/$VERIFICATION_RUN_ID" ]
}

@test "helpers reject cross-run and broad deletion without touching other state" {
  local other outside
  other='run-20260817T000001Z-fedcba9876543210'
  outside="$WORKDIR/ordinary-data"
  mkdir "$VERIFICATION_ROOT/$VERIFICATION_RUN_ID" "$VERIFICATION_ROOT/$other" "$outside"
  touch "$outside/preserve"

  run verification_remove_namespace "$VERIFICATION_ROOT" "$other"
  [ "$status" -ne 0 ]
  [[ $output == *"not owned by this invocation"* ]]

  run verification_remove_namespace "$VERIFICATION_ROOT" 'run-20260817T000000Z-*'
  [ "$status" -ne 0 ]

  [ -d "$VERIFICATION_ROOT/$VERIFICATION_RUN_ID" ]
  [ -d "$VERIFICATION_ROOT/$other" ]
  [ -f "$outside/preserve" ]
}
