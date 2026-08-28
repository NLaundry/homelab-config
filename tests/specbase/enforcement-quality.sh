#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
SPEC_ROOT=${SPEC_ROOT:-"$ROOT/specbase/specs"}
CONFIG_FILE=${CONFIG_FILE:-"$ROOT/specbase/config.yaml"}
SCOPE_FILE=${SCOPE_FILE:-"$ROOT/tests/specbase/enforcement-observations.json"}
EVIDENCE_DIR=${EVIDENCE_DIR:-"$ROOT/tests/specbase/evidence"}
NOW_EPOCH=${NOW_EPOCH:-$(date -u +%s)}

fail() {
	printf 'enforcement-quality: %s\n' "$*" >&2
	exit 1
}
need() { command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"; }

configured_lenses() {
	yq -r '.specModel.planes[].reviewLens' "$CONFIG_FILE"
	printf '%s\n' enforcement
}

binding_rows() {
	local enforcement spec spec_id
	while IFS= read -r enforcement; do
		spec=${enforcement%/enforcement.yaml}/spec.md
		spec_id=$(awk '/^id:/ {print $2; exit}' "$spec")
		yq -o=json -I=0 '.bindings' "$enforcement" | jq -r --arg spec "$spec_id" --arg file "$enforcement" '
      to_entries[] |
      [$spec,.key,.value.type,.value.source,
       (if (.value.covers|type)=="array" then (.value.covers|join(",")) else .value.covers end),$file] | @tsv'
	done < <(find "$SPEC_ROOT" -name enforcement.yaml -type f | LC_ALL=C sort)
}

check_source_fragment() {
	local file=$1 fragment=$2
	case $file in
	*.md) grep -Eq "^#{1,6} ${fragment//-/[- ]}" "$file" ;;
	*.sh) grep -Fq "$fragment" "$file" ;;
	*) grep -Fq "$fragment" "$file" ;;
	esac
}

check_targets() {
	local spec binding type source covers enforcement file fragment
	while IFS=$'\t' read -r spec binding type source covers enforcement; do
		if [[ $type == review ]]; then
			local lenses
			lenses=$(configured_lenses)
			grep -Fxq "$source" <<<"$lenses" ||
				fail "$spec/$binding target resolution failed: review lens '$source' is not configured"
			continue
		fi
		file=${source%%#*}
		fragment=''
		[[ $source == *'#'* ]] && fragment=${source#*#}
		[[ -f "$ROOT/$file" ]] || fail "$spec/$binding target resolution failed: '$file' does not exist"
		if [[ -n $fragment ]]; then
			check_source_fragment "$ROOT/$file" "$fragment" ||
				fail "$spec/$binding target resolution failed: fragment '$fragment' is absent from '$file'"
		fi
	done < <(binding_rows)
	printf 'targets: every binding source and selector/anchor resolves\n'
}

check_scopes() {
	[[ -f "$SCOPE_FILE" ]] || fail "scope declaration file not found: $SCOPE_FILE"
	jq -e '.bindings | type == "object"' "$SCOPE_FILE" >/dev/null || fail 'scope declaration root is invalid'
	local spec binding type source covers enforcement key declared expected observations
	while IFS=$'\t' read -r spec binding type source covers enforcement; do
		key="$spec/$binding"
		if [[ $type != review && $type != manual ]]; then
			jq -e --arg key "$key" '.bindings | has($key)' "$SCOPE_FILE" >/dev/null ||
				fail "$key assertion scope is undeclared for automated binding"
			declared=$(jq -c -S --arg key "$key" '.bindings[$key] | keys | sort' "$SCOPE_FILE")
			expected=$(tr ',' '\n' <<<"$covers" | jq -Rsc 'split("\n")|map(select(length>0))|sort')
			[[ $declared == "$expected" ]] ||
				fail "$key assertion scope mismatch: expected $expected, observed $declared"
			observations=$(jq -r --arg key "$key" '.bindings[$key][] | .[]' "$SCOPE_FILE")
			[[ -n $observations ]] || fail "$key assertion scope has no direct observations"
			if grep -Eiq 'helper (exists|present)|wrapper (ran|passed|success)|suite (ran|passed|success)|file exists|script exists' <<<"$observations"; then
				fail "$key assertion scope uses helper-existence or wrapper-only evidence: $observations"
			fi
		fi
	done < <(binding_rows)
	printf 'scopes: every automated binding declares direct requirement observations\n'
}

validate_record() {
	local file=$1 status type observed fresh observed_epoch fresh_epoch record_id observed_shape
	if ! jq -e '
    (.id|type)=="string" and (.binding|type)=="string" and
    (.type|IN("live","manual","drill","review")) and
    (.status|IN("current","deferred")) and
    (.environment|type)=="string" and (.sourcePersona|type)=="string" and
    (.limitations|type)=="string" and (.limitations|length)>0 and
    (.mutation|type)=="object" and (.mutation.mutating|type)=="boolean" and
    (.mutation.blastRadius|type)=="string" and
    (.cleanup|type)=="object" and (.cleanup.required|type)=="boolean" and
    (.cleanup.result|type)=="string"
  ' "$file" >/dev/null; then
		record_id=$(jq -r '.id // "<missing>"' "$file" 2>/dev/null || printf '<invalid-json>')
		observed_shape=$(jq -c '{id,binding,type,status,environment,sourcePersona,limitations,mutation,cleanup}' "$file" 2>/dev/null || printf '<invalid-json>')
		fail "evidence record $record_id schema mismatch in $file: expected typed identity/binding/type/status/environment/persona/limitations/mutation/cleanup fields, observed $observed_shape"
	fi
	if jq -e '.. | objects | to_entries[]? | select(.key|test("secret|password|privateKey";"i"))' "$file" >/dev/null ||
		grep -Eq 'BEGIN ([A-Z ]+ )?PRIVATE KEY' "$file"; then
		fail "evidence record may contain secret material: $file"
	fi
	status=$(jq -r '.status' "$file")
	type=$(jq -r '.type' "$file")
	if [[ $status == current ]]; then
		jq -e '(.revision|type)=="string" and (.revision|length)>0 and (.observedAt|type)=="string" and (.freshUntil|type)=="string"' "$file" >/dev/null ||
			fail "current evidence lacks revision/time/freshness metadata: $file"
		if [[ $EVIDENCE_DIR == "$ROOT/tests/specbase/evidence" ]]; then
			local expected_revision actual_revision attestation_path record_id run_json log_path expected_log_sha actual_log_sha
			expected_revision="implementation-sha256:$("$ROOT"/tests/specbase/implementation-digest.sh)"
			actual_revision=$(jq -r '.revision' "$file")
			[[ $actual_revision == "$expected_revision" ]] ||
				fail "current evidence revision mismatch in $file: expected $expected_revision, observed $actual_revision"
			attestation_path=$(jq -r '.attestation // ""' "$file")
			[[ -n $attestation_path && -f "$ROOT/$attestation_path" ]] ||
				fail "current evidence has no resolvable execution attestation: $file -> ${attestation_path:-<missing>}"
			record_id=$(jq -r '.id' "$file")
			run_json=$(jq -c --arg id "$record_id" --arg revision "$actual_revision" '
				select(.implementationDigest == $revision) | .runs[$id] |
				select(.exit == 0 and (.log|type)=="string" and (.logSha256|type)=="string")' "$ROOT/$attestation_path")
			[[ -n $run_json ]] || fail "execution attestation does not bind current successful run $record_id to $actual_revision: $attestation_path"
			log_path=$(jq -r '.log' <<<"$run_json")
			expected_log_sha=$(jq -r '.logSha256' <<<"$run_json")
			[[ -f "$ROOT/$log_path" ]] || fail "attested execution log is missing for $record_id: $log_path"
			actual_log_sha=$(sha256sum "$ROOT/$log_path" | awk '{print $1}')
			[[ $actual_log_sha == "$expected_log_sha" ]] ||
				fail "attested execution log digest mismatch for $record_id: expected $expected_log_sha, observed $actual_log_sha"
			grep -Fq "implementation_digest=$actual_revision" "$ROOT/$log_path" ||
				fail "execution log for $record_id did not emit implementation digest $actual_revision"
		fi
		observed=$(jq -r '.observedAt' "$file")
		fresh=$(jq -r '.freshUntil' "$file")
		observed_epoch=$(date -u -d "$observed" +%s 2>/dev/null) || fail "invalid observedAt in $file: $observed"
		fresh_epoch=$(date -u -d "$fresh" +%s 2>/dev/null) || fail "invalid freshUntil in $file: $fresh"
		((observed_epoch <= NOW_EPOCH + 300)) || fail "future-dated evidence is unusable: $file"
		((fresh_epoch >= NOW_EPOCH)) || fail "stale evidence is unusable: $file"
		((fresh_epoch >= observed_epoch)) || fail "freshness precedes observation: $file"
	else
		jq -e '(.deferralReason|type)=="string" and (.deferralReason|length)>0' "$file" >/dev/null ||
			fail "deferred evidence lacks an explicit reason: $file"
	fi
	if jq -e '.mutation.mutating == true' "$file" >/dev/null; then
		jq -e '(.mutation.namespace|type)=="string" and (.mutation.namespace|test("(RUN_ID|timestamp|random|unique)";"i"))' "$file" >/dev/null ||
			fail "unsafe live mutation namespace metadata: $file"
		jq -e '.cleanup.required == true and (.cleanup.target|type)=="string" and (.cleanup.target|length)>0' "$file" >/dev/null ||
			fail "mutating evidence lacks exact cleanup metadata: $file"
	fi
	if [[ $status == current ]] && jq -e '.cleanup.required == true and .cleanup.result != "success"' "$file" >/dev/null; then
		fail "evidence cleanup left residue or an unknown result: $file"
	fi
	printf 'record %s (%s/%s) conforms\n' "$(jq -r '.id' "$file")" "$type" "$status"
}

check_records() {
	[[ -d "$EVIDENCE_DIR" ]] || fail "evidence directory not found: $EVIDENCE_DIR"
	local found=false file
	while IFS= read -r file; do
		found=true
		validate_record "$file"
	done < <(find "$EVIDENCE_DIR" -name '*.json' -type f | LC_ALL=C sort)
	$found || fail "no evidence records found under $EVIDENCE_DIR"
	printf 'records: provenance, freshness, limitations, blast radius, and cleanup metadata conform\n'
}

run_mode() {
	case "$1" in
	targets) check_targets ;;
	scopes) check_scopes ;;
	records) check_records ;;
	conformance)
		check_targets
		check_scopes
		check_records
		;;
	*) fail "unknown selector: $1" ;;
	esac
}

case ${1:-} in
'') fail 'usage: enforcement-quality.sh {conformance|targets|scopes|records}' ;;
*)
	need jq
	need yq
	run_mode "$1"
	;;
esac
