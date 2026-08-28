#!/usr/bin/env bats

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  CHECKER="$ROOT/tests/specbase/enforcement-quality.sh"
  WORKDIR=$(mktemp -d)
  SPEC_ROOT="$WORKDIR/specs"
  EVIDENCE_DIR="$WORKDIR/evidence"
  SCOPE_FILE="$WORKDIR/scopes.json"
  mkdir -p "$SPEC_ROOT/governance/fixture" "$EVIDENCE_DIR"
  cat >"$SPEC_ROOT/governance/fixture/spec.md" <<'EOF'
---
id: governance.fixture
---

## Purpose
Fixture.

### Requirement: One
**ID:** `one`
The fixture SHALL establish one.

#### Scenario: One
**ID:** `one-scenario`
- **WHEN** inspected
- **THEN** one is established

### Requirement: Two
**ID:** `two`
The fixture SHALL establish two.

#### Scenario: Two
**ID:** `two-scenario`
- **WHEN** inspected
- **THEN** two is established
EOF
  cat >"$SPEC_ROOT/governance/fixture/enforcement.yaml" <<EOF
bindings:
  fixture-binding:
    type: test
    covers:
      - one
      - two
    source: tests/harness/enforcement-quality.bats
EOF
  cat >"$EVIDENCE_DIR/valid.json" <<'EOF'
{
  "id": "valid-deferred",
  "binding": "governance.fixture/fixture-binding",
  "type": "manual",
  "status": "deferred",
  "deferralReason": "Controlled fixture.",
  "environment": "isolated fixture",
  "sourcePersona": "fixture",
  "limitations": "Not current evidence.",
  "mutation": {"mutating": false, "blastRadius": "None."},
  "cleanup": {"required": false, "result": "not-applicable"}
}
EOF
}

teardown() { rm -rf "$WORKDIR"; }

run_checker() {
  env SPEC_ROOT="$SPEC_ROOT" SCOPE_FILE="$SCOPE_FILE" EVIDENCE_DIR="$EVIDENCE_DIR" \
    NOW_EPOCH=1787947200 "$CHECKER" "$@"
}

write_scopes() {
  local one=$1 two=$2
  jq -n --arg one "$one" --arg two "$two" '{bindings:{"governance.fixture/fixture-binding":{one:[$one],two:[$two]}}}' >"$SCOPE_FILE"
}

@test "valid direct observations and deferred metadata conform" {
  write_scopes 'direct result one' 'direct result two'
  run run_checker scopes
  [ "$status" -eq 0 ]
  run run_checker records
  [ "$status" -eq 0 ]
}

@test "helper-existence evidence is rejected" {
  write_scopes 'helper exists' 'direct result two'
  run run_checker scopes
  [ "$status" -ne 0 ]
  [[ $output == *"helper-existence or wrapper-only evidence"* ]]
}

@test "wrapper-only evidence is rejected" {
  write_scopes 'wrapper passed' 'direct result two'
  run run_checker scopes
  [ "$status" -ne 0 ]
  [[ $output == *"helper-existence or wrapper-only evidence"* ]]
}

@test "overbroad coverage without every observation is rejected" {
  jq -n '{bindings:{"governance.fixture/fixture-binding":{one:["direct result one"]}}}' >"$SCOPE_FILE"
  run run_checker scopes
  [ "$status" -ne 0 ]
  [[ $output == *"assertion scope mismatch"* ]]
}

@test "current evidence without provenance is rejected" {
  write_scopes 'direct result one' 'direct result two'
  jq '.status="current" | del(.deferralReason)' "$EVIDENCE_DIR/valid.json" >"$EVIDENCE_DIR/missing.json"
  rm "$EVIDENCE_DIR/valid.json"
  run run_checker records
  [ "$status" -ne 0 ]
  [[ $output == *"lacks revision/time/freshness metadata"* ]]
}

@test "stale current evidence is rejected" {
  write_scopes 'direct result one' 'direct result two'
  jq '.status="current" | del(.deferralReason) |
      .revision="fixture" | .observedAt="2026-08-01T00:00:00Z" | .freshUntil="2026-08-02T00:00:00Z"' \
    "$EVIDENCE_DIR/valid.json" >"$EVIDENCE_DIR/stale.json"
  rm "$EVIDENCE_DIR/valid.json"
  run run_checker records
  [ "$status" -ne 0 ]
  [[ $output == *"stale evidence is unusable"* ]]
}

@test "unsafe live mutation metadata is rejected" {
  write_scopes 'direct result one' 'direct result two'
  jq '.status="current" | del(.deferralReason) |
      .revision="fixture" | .observedAt="2026-08-28T16:00:00Z" | .freshUntil="2026-08-29T16:00:00Z" |
      .mutation={"mutating":true,"namespace":"shared","blastRadius":"all shares"} |
      .cleanup={"required":false,"result":"not-applicable"}' \
    "$EVIDENCE_DIR/valid.json" >"$EVIDENCE_DIR/unsafe.json"
  rm "$EVIDENCE_DIR/valid.json"
  run run_checker records
  [ "$status" -ne 0 ]
  [[ $output == *"unsafe live mutation namespace metadata"* ]]
}

@test "a missing binding target is rejected with binding identity" {
  write_scopes 'direct result one' 'direct result two'
  sed -i.bak 's#tests/harness/enforcement-quality.bats#tests/harness/missing-fixture.bats#' \
    "$SPEC_ROOT/governance/fixture/enforcement.yaml"
  run run_checker targets
  [ "$status" -ne 0 ]
  [[ $output == *"governance.fixture/fixture-binding target resolution failed"* ]]
}
