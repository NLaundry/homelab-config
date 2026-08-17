#!/usr/bin/env bash
set -euo pipefail

verification_new_run_id() {
  local random
  random=$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')
  printf 'run-%(%Y%m%dT%H%M%SZ)T-%s\n' -1 "$random"
}

verification_validate_run_id() {
  local run_id=${1:-}
  [[ $run_id =~ ^run-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{16}$ ]] || {
    printf 'invalid verification run ID: %q\n' "$run_id" >&2
    return 2
  }
}

verification_namespace_path() {
  local root=${1:?verification root is required}
  local run_id=${2:?verification run ID is required}
  local resolved_root

  verification_validate_run_id "$run_id"
  [[ ${VERIFICATION_RUN_ID:-} == "$run_id" ]] || {
    printf 'run ID is not owned by this invocation: %s\n' "$run_id" >&2
    return 2
  }
  [[ -d $root && ! -L $root ]] || {
    printf 'verification root is not a non-symlink directory: %s\n' "$root" >&2
    return 2
  }
  resolved_root=$(cd "$root" && pwd -P)
  [[ $resolved_root == /* && $resolved_root != / ]] || {
    printf 'unsafe verification root: %s\n' "$resolved_root" >&2
    return 2
  }
  printf '%s/%s\n' "$resolved_root" "$run_id"
}

verification_create_namespace() {
  local target
  target=$(verification_namespace_path "$1" "$2")
  local mkdir_command=mkdir
  [[ -x /bin/mkdir ]] && mkdir_command=/bin/mkdir
  "$mkdir_command" -m 0700 -- "$target" || {
    printf 'verification namespace already exists or cannot be created: %s\n' "$target" >&2
    return 1
  }
}

verification_remove_namespace() {
  local target
  target=$(verification_namespace_path "$1" "$2")
  [[ -d $target && ! -L $target ]] || {
    printf 'verification namespace is not a removable direct-child directory: %s\n' "$target" >&2
    return 2
  }
  local rmdir_command=rmdir
  [[ -x /bin/rmdir ]] && rmdir_command=/bin/rmdir
  "$rmdir_command" -- "$target"
  [[ ! -e $target && ! -L $target ]] || {
    printf 'verification namespace remains after cleanup: %s\n' "$target" >&2
    return 1
  }
}
