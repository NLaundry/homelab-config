#!/usr/bin/env bats

# bats file_tags=deployment,nas
# shellcheck source=tests/verify/lib/deployment-health.sh
source "$BATS_TEST_DIRNAME/lib/deployment-health.sh"

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  NAS_ADDRESS=${HOMELAB_NAS_ADDRESS:-"$(yq -r '.all.children.nas.hosts.nasty.ansible_host' "$ROOT/ansible/inventory.yml")"}
  SSH_COMMAND=${HOMELAB_DEPLOYMENT_SSH_COMMAND:-ssh}
  SSH_IDENTITY=${HOMELAB_DEPLOYMENT_SSH_IDENTITY:-"$HOME/.ssh/id_ed25519"}
  SSH_DEADLINE_SECONDS=${HOMELAB_DEPLOYMENT_SSH_DEADLINE_SECONDS:-60}
  TARGET="operator@$NAS_ADDRESS"
}

@test "the activated NAS becomes reachable over SSH within a finite deadline" {
  run wait_for_ssh
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
}

@test "the activated NAS has no failed systemd units" {
  run assert_systemd_healthy
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
}

@test "the activated NAS exposes an existing NixOS system generation" {
  run assert_active_generation
  if [ "$status" -ne 0 ]; then printf '%s\n' "$output" >&2; fi
  [ "$status" -eq 0 ]
  [[ $output == *"active deployment generation: /nix/store/"* ]]
}
