#!/usr/bin/env bats

@test "selected SSH transport is present in the live-runner closure" {
  [[ $(command -v ssh) == /nix/store/* ]]
  run ssh -V
  [ "$status" -eq 0 ]
}
