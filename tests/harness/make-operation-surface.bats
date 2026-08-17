#!/usr/bin/env bats

setup() {
  ROOT=${HOMELAB_ROOT:-"$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"}
  WORKDIR=$(mktemp -d)
}

teardown() {
  rm -rf "$WORKDIR"
}

assert_make_surface() {
  local makefile=$1
  local database registry help operation

  database=$(make -rR -f "$makefile" -pn help 2>&1) || {
    printf '%s\n' "$database"
    return 1
  }

  registry=$(printf '%s\n' "$database" | awk '
    $1 == "OPERATIONS" && $2 == ":=" {
      for (i = 3; i <= NF; i++) printf "%s%s", (i == 3 ? "" : " "), $i
      print ""
      exit
    }
  ')
  [[ -n $registry ]] || {
    printf 'operation registry is missing\n' >&2
    return 1
  }

  help=$(make -rR --no-print-directory -f "$makefile" help 2>&1) || {
    printf '%s\n' "$help"
    return 1
  }

  for operation in $registry; do
    printf '%s\n' "$database" | awk -v target="$operation" '
      $1 == target ":" { found = 1 }
      END { exit(found ? 0 : 1) }
    ' || {
      printf 'registered operation has no same-named target: %s\n' "$operation" >&2
      return 1
    }

    printf '%s\n' "$database" | awk -v target="$operation" '
      $1 == ".PHONY:" {
        for (i = 2; i <= NF; i++) if ($i == target) found = 1
      }
      END { exit(found ? 0 : 1) }
    ' || {
      printf 'registered operation is not phony: %s\n' "$operation" >&2
      return 1
    }

    printf '%s\n' "$help" | awk -v target="$operation" '
      $1 == target { found = 1 }
      END { exit(found ? 0 : 1) }
    ' || {
      printf 'registered operation is undocumented: %s\n' "$operation" >&2
      return 1
    }
  done
}

write_fixture() {
  local path=$1 registry=$2 phony=$3 targets=$4 docs=$5 target
  {
    printf 'OPERATIONS := %s\n' "$registry"
    printf 'DOCS := %s\n' "$docs"
    printf '.PHONY: help %s\n' "$phony"
    printf 'help:\n'
    # Literal Make variables belong in the generated fixture.
    # shellcheck disable=SC2016
    printf '\t%s\n' '@for operation in $(DOCS); do printf "  %s  fixture operation\n" "$$operation"; done'
    for target in $targets; do
      printf '%s:\n\t@:\n' "$target"
    done
  } >"$path"
}

@test "the root Makefile exposes every registered operation" {
  run assert_make_surface "$ROOT/Makefile"
  [ "$status" -eq 0 ]
}

@test "a controlled valid operation surface passes" {
  write_fixture "$WORKDIR/Makefile" "alpha beta" "alpha beta" "alpha beta" "alpha beta"
  run assert_make_surface "$WORKDIR/Makefile"
  [ "$status" -eq 0 ]
}

@test "a missing registered target is rejected" {
  write_fixture "$WORKDIR/Makefile" "alpha beta" "alpha" "alpha" "alpha beta"
  run assert_make_surface "$WORKDIR/Makefile"
  [ "$status" -ne 0 ]
  [[ $output == *"no same-named target: beta"* ]]
}

@test "an undocumented registered target is rejected" {
  write_fixture "$WORKDIR/Makefile" "alpha beta" "alpha beta" "alpha beta" "alpha"
  run assert_make_surface "$WORKDIR/Makefile"
  [ "$status" -ne 0 ]
  [[ $output == *"undocumented: beta"* ]]
}

@test "a differently named target is rejected" {
  write_fixture "$WORKDIR/Makefile" "alpha beta" "alpha gamma" "alpha gamma" "alpha beta"
  run assert_make_surface "$WORKDIR/Makefile"
  [ "$status" -ne 0 ]
  [[ $output == *"no same-named target: beta"* ]]
}

@test "a non-phony registered target is rejected" {
  write_fixture "$WORKDIR/Makefile" "alpha beta" "alpha" "alpha beta" "alpha beta"
  run assert_make_surface "$WORKDIR/Makefile"
  [ "$status" -ne 0 ]
  [[ $output == *"not phony: beta"* ]]
}
