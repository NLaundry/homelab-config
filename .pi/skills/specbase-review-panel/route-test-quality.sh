#!/usr/bin/env bash
set -euo pipefail

route='code-quality	code-quality/testing'
selected=false

case ${1:-} in
  '' | --records) ;;
  *)
    printf 'usage: %s [--records]\n' "${0##*/}" >&2
    exit 2
    ;;
esac

is_test_path() {
  [[ $1 == tests/* ]]
}

changed_path_records() {
  case ${1:-} in
    '')
      git diff --cached --name-status --diff-filter=ACDMRTUXB
      ;;
    --records)
      cat
      ;;
  esac
}

while IFS=$'\t' read -r status first_path second_path _; do
  [[ -n $status ]] || continue
  status=${status%%[0-9]*}
  case $status in
    A | M | D | T | U)
      is_test_path "$first_path" && selected=true
      ;;
    R | C)
      if is_test_path "$first_path" || is_test_path "$second_path"; then
        selected=true
      fi
      ;;
    *)
      printf 'unsupported changed-path status: %s\n' "$status" >&2
      exit 2
      ;;
  esac
done < <(changed_path_records "${1:-}")

if $selected; then
  printf '%b\n' "$route"
fi
