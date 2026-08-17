#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
CONFIG_FILE=${SPECBASE_CONFIG_FILE:-"$ROOT/specbase/config.yaml"}
REVIEW_SKILL_FILE=${REVIEW_SKILL_FILE:-"$ROOT/.pi/skills/specbase-review-panel/SKILL.md"}
TEST_QUALITY_ROUTER_FILE=${TEST_QUALITY_ROUTER_FILE:-"$ROOT/.pi/skills/specbase-review-panel/route-test-quality.sh"}
COVERAGE_JSON_FILE=${COVERAGE_JSON_FILE:-}

fail() {
  printf 'specbase-instruments: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

check_config() {
  require_command yq
  require_command jq
  [[ -f "$CONFIG_FILE" ]] || fail "configuration file not found: $CONFIG_FILE"

  local schema actual_planes expected_planes
  schema=$(yq -r '.schema // ""' "$CONFIG_FILE")
  [[ "$schema" == "spec-driven-governed" ]] ||
    fail "expected schema spec-driven-governed in $CONFIG_FILE, found ${schema:-<missing>}"

  actual_planes=$(yq -o=json -I=0 '[.specModel.planes[].id] | sort' "$CONFIG_FILE")
  expected_planes='["agents","architecture","behavior","code-quality","ops"]'
  [[ "$actual_planes" == "$expected_planes" ]] ||
    fail "plane roster mismatch in $CONFIG_FILE: expected $expected_planes, found $actual_planes"

  printf 'config: schema and plane roster conform\n'
}

coverage_json() {
  if [[ -n "$COVERAGE_JSON_FILE" ]]; then
    [[ -f "$COVERAGE_JSON_FILE" ]] || fail "coverage JSON not found: $COVERAGE_JSON_FILE"
    cat "$COVERAGE_JSON_FILE"
  else
    require_command specbase
    (cd "$ROOT" && specbase coverage --json)
  fi
}

skill_lenses() {
  awk -F '|' '
    /^\| `[^`]+` \|/ {
      lens=$2; question=$3; scope=$4
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", lens)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", question)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", scope)
      gsub(/`/, "", lens)
      gsub(/`/, "", scope)
      if (lens != "behavioural" && lens != "architectural" &&
          lens != "ops" && lens != "code-quality" && lens != "enforcement") next
      if (question == "") {
        printf "empty question for lens %s\n", lens > "/dev/stderr"
        exit 2
      }
      cross="false"
      if (lens == "enforcement") {
        scope=""
        cross="true"
      } else {
        sub(/\/\*\*$/, "", scope)
      }
      print lens "\t" scope "\t" cross
    }
  ' "$REVIEW_SKILL_FILE" | LC_ALL=C sort
}

check_lenses() {
  require_command jq
  [[ -f "$REVIEW_SKILL_FILE" ]] || fail "review-panel skill not found: $REVIEW_SKILL_FILE"

  local expected actual diff_file
  expected=$(mktemp)
  actual=$(mktemp)
  diff_file=$(mktemp)
  # Expand local paths now because the variables are unavailable at shell exit.
  # shellcheck disable=SC2064
  trap "rm -f '$expected' '$actual' '$diff_file'" EXIT

  skill_lenses >"$expected" || fail "could not parse the review-panel lens table"
  coverage_json | jq -r '
    .summary.review.lenses[] |
    [.lens, .scope, (.crossCutting | tostring)] | @tsv
  ' | LC_ALL=C sort >"$actual"

  if ! diff -u "$expected" "$actual" >"$diff_file"; then
    cat "$diff_file" >&2
    fail "review-panel skill lenses differ from the resolved coverage lens set"
  fi

  [[ $(wc -l <"$expected" | tr -d ' ') == 5 ]] ||
    fail "expected exactly five declared review lenses in $REVIEW_SKILL_FILE"

  printf 'lenses: declared and resolved lens rosters conform\n'
}

assert_test_quality_route() {
  local fixture=$1 expected=$2 actual fixture_label
  printf -v fixture_label '%q' "$fixture"
  actual=$(printf '%s' "$fixture" | "$TEST_QUALITY_ROUTER_FILE" --records) ||
    fail "test-quality router rejected controlled fixture: $fixture_label"
  [[ $actual == "$expected" ]] ||
    fail "test-quality route mismatch for $fixture_label: expected '${expected:-<none>}', found '${actual:-<none>}'"
}

assert_index_test_quality_route() (
  local workdir index blob actual expected
  workdir=$(mktemp -d)
  trap 'rm -rf "$workdir"' EXIT
  index=$workdir/index
  cp "$ROOT/.git/index" "$index"
  blob=$(git -C "$ROOT" rev-parse HEAD:README.md)
  GIT_INDEX_FILE=$index git -C "$ROOT" update-index --add \
    --cacheinfo 100644 "$blob" tests/controlled-routing.bats
  actual=$(cd "$ROOT" && GIT_INDEX_FILE=$index "$TEST_QUALITY_ROUTER_FILE")
  expected=$'code-quality\tcode-quality/testing'
  [[ $actual == "$expected" ]] || {
    printf 'index-produced route mismatch: expected %q, found %q\n' \
      "$expected" "$actual" >&2
    return 1
  }
)

check_test_quality_routing() {
  [[ -x "$TEST_QUALITY_ROUTER_FILE" ]] ||
    fail "test-quality router is not executable: $TEST_QUALITY_ROUTER_FILE"
  [[ -f "$REVIEW_SKILL_FILE" ]] ||
    fail "review-panel skill not found: $REVIEW_SKILL_FILE"

  local contract
  contract=$(awk '
    /test-quality-route-contract:start/ { in_contract = 1; next }
    /test-quality-route-contract:end/ { in_contract = 0 }
    in_contract { print }
  ' "$REVIEW_SKILL_FILE")
  [[ -n $contract ]] || fail "review-panel skill has no bounded test-quality route contract"
  grep -Fq '.pi/skills/specbase-review-panel/route-test-quality.sh' <<<"$contract" ||
    fail "route contract does not invoke the test-quality router"
  grep -Fq 'with no arguments' <<<"$contract" ||
    fail "route contract does not invoke the canonical producer mode"
  grep -Fq 'git diff --cached --name-status --diff-filter=ACDMRTUXB' <<<"$contract" ||
    fail "route contract does not declare the selected-change producer"
  grep -Fq "select the \`code-quality\` lens" <<<"$contract" ||
    fail "route contract does not apply the emitted lens"
  grep -Fq "load the current \`code-quality/testing\` pair as policy" <<<"$contract" ||
    fail "route contract does not apply the emitted policy"
  if ! grep -Fq 'remains' <<<"$contract" || ! grep -Fq 'advisory and non-gating' <<<"$contract"; then
    fail "route contract does not preserve advisory routing semantics"
  fi

  assert_index_test_quality_route ||
    fail "canonical staged-index producer did not select the testing policy"

  local route fixture
  route=$'code-quality\tcode-quality/testing'
  for fixture in \
    $'A\ttests/new.bats\n' \
    $'M\ttests/existing.bats\n' \
    $'D\ttests/retired.bats\n' \
    $'R100\ttests/old.bats\tdocs/new.md\n' \
    $'R091\tdocs/old.md\ttests/new.bats\n'; do
    assert_test_quality_route "$fixture" "$route"
  done

  for fixture in \
    $'M\tREADME.md\n' \
    $'A\tcontest/example.bats\n' \
    $'A\ttest/example.bats\n' \
    $'R100\tdocs/old.md\tdocs/new.md\n'; do
    assert_test_quality_route "$fixture" ''
  done

  printf 'routing: test paths select only the advisory testing policy\n'
}

check_validate() {
  require_command specbase
  (cd "$ROOT" && specbase validate --specs --strict --json)
}

usage() {
  printf 'usage: %s {all|config|lenses|test-quality-routing|validate}\n' "${0##*/}" >&2
  exit 2
}

case ${1:-} in
  all)
    check_config
    check_validate
    check_lenses
    check_test_quality_routing
    ;;
  config) check_config ;;
  lenses) check_lenses ;;
  test-quality-routing) check_test_quality_routing ;;
  validate) check_validate ;;
  *) usage ;;
esac
