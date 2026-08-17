#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
CONFIG_FILE=${SPECBASE_CONFIG_FILE:-"$ROOT/specbase/config.yaml"}
REVIEW_SKILL_FILE=${REVIEW_SKILL_FILE:-"$ROOT/.pi/skills/specbase-review-panel/SKILL.md"}
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

check_validate() {
  require_command specbase
  (cd "$ROOT" && specbase validate --specs --strict --json)
}

usage() {
  printf 'usage: %s {all|config|lenses|validate}\n' "${0##*/}" >&2
  exit 2
}

case ${1:-} in
  all)
    check_config
    check_validate
    check_lenses
    ;;
  config) check_config ;;
  lenses) check_lenses ;;
  validate) check_validate ;;
  *) usage ;;
esac
