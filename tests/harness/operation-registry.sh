#!/usr/bin/env bash

operation_registry() {
  local makefile=${1:?makefile is required}
  local database registry

  database=$(make -rR -f "$makefile" -pn help 2>/dev/null) || {
    printf 'failed to inspect Make operation registry: %s\n' "$makefile" >&2
    return 1
  }
  registry=$(awk '
    $1 == "OPERATIONS" && $2 == ":=" {
      for (i = 3; i <= NF; i++) print $i
      exit
    }
  ' <<<"$database")
  [[ -n $registry ]] || {
    printf 'Make operation registry is empty: %s\n' "$makefile" >&2
    return 1
  }
  printf '%s\n' "$registry"
}

assert_operation_registered() {
  local makefile=${1:?makefile is required}
  local operation=${2:?operation is required}
  local registry

  registry=$(operation_registry "$makefile") || return 1
  grep -Fxq "$operation" <<<"$registry" || {
    printf 'required operation is not registered: %s\n' "$operation" >&2
    return 1
  }
}
