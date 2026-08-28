#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2064
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

assert_config_file() {
	local file=$1 schema actual_planes expected_planes actual_lenses expected_lenses
	[[ -f "$file" ]] || {
		printf 'configuration file not found: %s\n' "$file" >&2
		return 1
	}
	schema=$(yq -r '.schema // ""' "$file")
	[[ "$schema" == "spec-driven-governed" ]] || {
		printf 'expected schema spec-driven-governed in %s, found %s\n' "$file" "${schema:-<missing>}" >&2
		return 1
	}
	actual_planes=$(yq -o=json -I=0 '[.specModel.planes[].id] | sort' "$file")
	expected_planes='["configuration","estate","governance","lifecycle","service"]'
	[[ "$actual_planes" == "$expected_planes" ]] || {
		printf 'plane roster mismatch in %s: expected %s, found %s\n' "$file" "$expected_planes" "$actual_planes" >&2
		return 1
	}
	actual_lenses=$(yq -o=json -I=0 '[.specModel.planes[] | {"id": .id, "reviewLens": .reviewLens}] | sort_by(.id)' "$file")
	expected_lenses='[{"id":"configuration","reviewLens":"configuration"},{"id":"estate","reviewLens":"estate"},{"id":"governance","reviewLens":"governance"},{"id":"lifecycle","reviewLens":"lifecycle"},{"id":"service","reviewLens":"service"}]'
	[[ "$actual_lenses" == "$expected_lenses" ]] || {
		printf 'plane lens assignments mismatch in %s: expected %s, found %s\n' "$file" "$expected_lenses" "$actual_lenses" >&2
		return 1
	}
}

check_config() {
	require_command yq
	require_command jq
	assert_config_file "$CONFIG_FILE" || fail 'governed configuration does not conform'
	printf 'config: schema, plane roster, and lens assignments conform\n'
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
    /^\| Lens \| Question \| Scope \|/ { in_table=1; next }
    in_table && /^\|---/ { next }
    in_table && /^\|/ {
      lens=$2; question=$3; scope=$4
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", lens)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", question)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", scope)
      gsub(/`/, "", lens); gsub(/`/, "", scope)
      if (lens == "" || question == "" || scope == "") {
        printf "invalid lens row: %s\n", $0 > "/dev/stderr"; exit 2
      }
      cross="false"
      if (lens == "enforcement") { scope=""; cross="true" }
      else { sub(/\/\*\*$/, "", scope) }
      print lens "\t" scope "\t" cross
      next
    }
    in_table { exit }
  ' "$REVIEW_SKILL_FILE" | LC_ALL=C sort
}

check_lenses() {
	require_command jq
	[[ -f "$REVIEW_SKILL_FILE" ]] || fail "review-panel skill not found: $REVIEW_SKILL_FILE"
	local expected actual diff_file
	expected=$(mktemp)
	actual=$(mktemp)
	diff_file=$(mktemp)
	trap "rm -f '$expected' '$actual' '$diff_file'" EXIT
	skill_lenses >"$expected" || fail 'could not parse the review-panel lens table'
	coverage_json | jq -r '.summary.review.lenses[] | [.lens,.scope,(.crossCutting|tostring)] | @tsv' |
		LC_ALL=C sort >"$actual"
	if ! diff -u "$expected" "$actual" >"$diff_file"; then
		cat "$diff_file" >&2
		fail 'review-panel skill lenses differ from the resolved coverage lens set'
	fi
	[[ $(wc -l <"$expected" | tr -d ' ') == 6 ]] ||
		fail "expected exactly six declared review lenses in $REVIEW_SKILL_FILE"
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
	trap "rm -rf '$workdir'" EXIT
	index=$workdir/index
	cp "$ROOT/.git/index" "$index"
	blob=$(git -C "$ROOT" rev-parse HEAD:README.md)
	GIT_INDEX_FILE=$index git -C "$ROOT" update-index --add --cacheinfo 100644 "$blob" tests/controlled-routing.bats
	actual=$(cd "$ROOT" && GIT_INDEX_FILE=$index "$TEST_QUALITY_ROUTER_FILE")
	expected=$'enforcement\tgovernance/enforcement-quality'
	[[ $actual == "$expected" ]] || {
		printf 'index-produced route mismatch: expected %q, found %q\n' "$expected" "$actual" >&2
		return 1
	}
)

check_test_quality_routing() {
	[[ -x "$TEST_QUALITY_ROUTER_FILE" ]] || fail "test-quality router is not executable: $TEST_QUALITY_ROUTER_FILE"
	[[ -f "$REVIEW_SKILL_FILE" ]] || fail "review-panel skill not found: $REVIEW_SKILL_FILE"
	local contract
	contract=$(awk '/test-quality-route-contract:start/ {on=1;next} /test-quality-route-contract:end/ {on=0} on {print}' "$REVIEW_SKILL_FILE")
	[[ -n $contract ]] || fail 'review-panel skill has no bounded test-quality route contract'
	grep -Fq 'Do not stop merely because no spec pair is touched' "$REVIEW_SKILL_FILE" ||
		fail 'review-panel control flow stops before test-only routing'
	grep -Fq '.pi/skills/specbase-review-panel/route-test-quality.sh' <<<"$contract" || fail 'route contract does not invoke the test-quality router'
	grep -Fq 'with no arguments' <<<"$contract" || fail 'route contract does not invoke canonical producer mode'
	grep -Fq 'git diff --cached --name-status --diff-filter=ACDMRTUXB' <<<"$contract" || fail 'route contract does not declare the selected-change producer'
	grep -Fq 'select the `enforcement`' <<<"$contract" || fail 'route contract does not apply the emitted lens'
	grep -Fq 'load the current `governance/enforcement-quality` pair as policy' <<<"$contract" || fail 'route contract does not apply the emitted policy'
	grep -Fq 'advisory and non-gating' <<<"$contract" || fail 'route contract does not preserve advisory semantics'
	assert_index_test_quality_route || fail 'canonical staged-index producer did not select enforcement-quality policy'

	local route fixture
	route=$'enforcement\tgovernance/enforcement-quality'
	for fixture in \
		$'A\ttests/new.bats\n' $'M\ttests/existing.bats\n' $'D\ttests/retired.bats\n' \
		$'R100\ttests/old.bats\tdocs/new.md\n' $'R091\tdocs/old.md\ttests/new.bats\n'; do
		assert_test_quality_route "$fixture" "$route"
	done
	for fixture in \
		$'M\tREADME.md\n' $'A\tcontest/example.bats\n' $'A\ttest/example.bats\n' \
		$'R100\tdocs/old.md\tdocs/new.md\n'; do
		assert_test_quality_route "$fixture" ''
	done
	printf 'routing: test paths select the advisory Enforcement lens with governance enforcement-quality policy\n'
}

expect_failure() {
	local expected=$1
	shift
	local output status=0
	output=$("$@" 2>&1) || status=$?
	[[ $status -ne 0 ]] || fail "controlled mutant unexpectedly passed: $expected"
	[[ $output == *"$expected"* ]] || fail "controlled mutant missed diagnostic '$expected': $output"
}

check_guidance() {
	local files=(
		"$ROOT/.pi/skills/specbase-apply-change/SKILL.md"
		"$ROOT/.pi/skills/specbase-archive-change/SKILL.md"
		"$ROOT/.pi/skills/specbase-explore/SKILL.md"
		"$ROOT/.pi/skills/specbase-propose/SKILL.md"
		"$ROOT/.pi/skills/specbase-review-panel/SKILL.md"
		"$ROOT/.pi/skills/specbase-ste-writing/SKILL.md"
		"$ROOT/.pi/prompts/spcb-apply.md"
		"$ROOT/.pi/prompts/spcb-archive.md"
		"$ROOT/.pi/prompts/spcb-explore.md"
		"$ROOT/.pi/prompts/spcb-propose.md"
		"$ROOT/.pi/prompts/spcb-review-panel.md"
	) file
	for file in "${files[@]}"; do [[ -f "$file" ]] || fail "generated guidance is missing: $file"; done
	if grep -En 'specs/(behavior|architecture|ops|code-quality|agents)/|`(behavior|architecture|ops|code-quality|agents)/' "${files[@]}"; then
		fail 'generated guidance retains a retired plane path'
	fi
	grep -Fq 'planes: [service, estate, configuration, lifecycle, governance]' \
		"$ROOT/.pi/skills/specbase-propose/SKILL.md" || fail 'proposal guidance lacks the exact new roster'
	grep -Fq 'Repository/control machinery is Governance' \
		"$ROOT/.pi/skills/specbase-explore/SKILL.md" || fail 'exploration guidance lacks the new decision order'
	printf 'guidance: generated skills and prompts use the homelab-native roster and decision order\n'
}

check_instrument_mutants() {
	require_command yq
	local workdir missing extra skill_missing skill_extra skill_scope
	workdir=$(mktemp -d)
	trap "rm -rf '$workdir'" EXIT
	missing=$workdir/missing.yaml
	extra=$workdir/extra.yaml
	yq 'del(.specModel.planes[] | select(.id == "service"))' "$CONFIG_FILE" >"$missing"
	yq '.specModel.planes += [{"id":"extra","purpose":"fixture","enforcementFlavor":"fixture","reviewLens":"extra"}]' "$CONFIG_FILE" >"$extra"
	expect_failure 'plane roster mismatch' env SPECBASE_CONFIG_FILE="$missing" "$0" config
	expect_failure 'plane roster mismatch' env SPECBASE_CONFIG_FILE="$extra" "$0" config

	skill_missing=$workdir/lens-missing.md
	skill_extra=$workdir/lens-extra.md
	skill_scope=$workdir/lens-scope.md
	grep -v '^| `service` |' "$REVIEW_SKILL_FILE" >"$skill_missing"
	awk '/^\| `enforcement` \|/ { print "| `extra` | Controlled extra lens. | `extra/**` |" } {print}' "$REVIEW_SKILL_FILE" >"$skill_extra"
	sed 's#`service/\*\*`#`estate/**`#' "$REVIEW_SKILL_FILE" >"$skill_scope"
	expect_failure 'review-panel skill lenses differ' env REVIEW_SKILL_FILE="$skill_missing" "$0" lenses
	expect_failure 'review-panel skill lenses differ' env REVIEW_SKILL_FILE="$skill_extra" "$0" lenses
	expect_failure 'review-panel skill lenses differ' env REVIEW_SKILL_FILE="$skill_scope" "$0" lenses
	printf 'mutants: missing/extra planes and missing/extra/scope-drift lenses rejected\n'
}

check_validate() {
	require_command specbase
	(cd "$ROOT" && specbase validate --strict --json)
}

usage() {
	printf 'usage: %s {all|config|lenses|test-quality-routing|validate|guidance|mutants}\n' "${0##*/}" >&2
	exit 2
}

case ${1:-} in
all)
	check_config
	check_validate
	check_lenses
	check_test_quality_routing
	check_guidance
	check_instrument_mutants
	;;
config) check_config ;;
lenses) check_lenses ;;
test-quality-routing) check_test_quality_routing ;;
validate) check_validate ;;
guidance) check_guidance ;;
mutants) check_instrument_mutants ;;
*) usage ;;
esac
