#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=tests/verify/lib/run-namespace.sh
source "$SCRIPT_DIR/run-namespace.sh"

fail() {
  printf 'smb-fixture-client: %s\n' "$*" >&2
  exit 1
}

file_mode() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"
}

file_owner_uid() {
  stat -c '%u' "$1" 2>/dev/null || stat -f '%u' "$1"
}

validate_auth_file() {
  local path=$1
  [[ -f $path && ! -L $path ]] || fail "authentication file is not a regular non-symlink: $path"
  [[ $(file_mode "$path") == 600 ]] || fail "authentication file mode is not 0600: $path"
  [[ $(file_owner_uid "$path") == "$(id -u)" ]] || fail "authentication file owner is not the current user: $path"
}

mount_authenticated() {
  local auth_file=$1 server=$2 share=$3 mountpoint=$4
  validate_auth_file "$auth_file"
  expect "$SCRIPT_DIR/mount-smb-with-auth.exp" "$auth_file" "$server" "$share" "$mountpoint"
}

is_authorization_denial() {
  local diagnostics=$1
  grep -Eq '^mount_smbfs: (server rejected the connection: Authentication error|mount error: //[^:]+: Permission denied)[[:space:]]*$' \
    "$diagnostics"
}

expect_denied() {
  local auth_file=${1:-} server=$2 share=$3 mountpoint diagnostics
  mountpoint=$(mktemp -d)
  diagnostics=$(mktemp)
  if [[ -n $auth_file ]]; then
    if mount_authenticated "$auth_file" "$server" "$share" "$mountpoint" >"$diagnostics" 2>&1; then
      /sbin/umount "$mountpoint" >/dev/null 2>&1 || true
      rm -f "$diagnostics"
      fail "endpoint unexpectedly accepted denied credentials"
    fi
  elif /sbin/mount_smbfs -N -o nobrowse,soft,nopassprompt -s \
    "//guest@$server/$share" "$mountpoint" >"$diagnostics" 2>&1; then
    /sbin/umount "$mountpoint" >/dev/null 2>&1 || true
    rm -f "$diagnostics"
    fail "endpoint unexpectedly accepted guest access"
  fi
  rmdir "$mountpoint"
  if ! is_authorization_denial "$diagnostics"; then
    printf 'denied check failed for a non-authorization reason:\n' >&2
    cat "$diagnostics" >&2
    rm -f "$diagnostics"
    return 1
  fi
  rm -f "$diagnostics"
  printf 'authorization denied as expected\n'
}

transaction() {
  local auth_file=$1 server=$2 share=$3 run_id=$4 fail_after_create=$5 simulate_cleanup_failure=$6
  local mountpoint namespace fixture renamed fixture_path expected observed original_error='' cleanup_error=''
  local created_namespace=false
  local mv_command=mv rm_command=rm
  [[ -x /bin/mv ]] && mv_command=/bin/mv
  [[ -x /bin/rm ]] && rm_command=/bin/rm
  mountpoint=$(mktemp -d)
  export VERIFICATION_RUN_ID=$run_id
  verification_validate_run_id "$run_id"

  if ! mount_authenticated "$auth_file" "$server" "$share" "$mountpoint"; then
    rmdir "$mountpoint"
    fail "authentication or mount failed for $server/$share"
  fi

  namespace="$mountpoint/$run_id"
  fixture="$namespace/fixture.txt"
  renamed="$namespace/fixture-renamed.txt"
  expected="homelab verification $run_id"

  if verification_create_namespace "$mountpoint" "$run_id"; then
    created_namespace=true
  else
    original_error='exclusive namespace creation failed'
  fi
  if [[ -z $original_error ]]; then
    printf '%s\n' "$expected" >"$fixture" || original_error='fixture write failed'
  fi
  if [[ -z $original_error ]]; then
    observed=$(<"$fixture") || original_error='fixture read failed'
    [[ $observed == "$expected" ]] || original_error='fixture content mismatch'
  fi
  if [[ -z $original_error && $fail_after_create == true ]]; then
    original_error='controlled assertion failure'
  fi
  if [[ -z $original_error ]]; then
    "$mv_command" -- "$fixture" "$renamed" || original_error='fixture rename failed'
  fi
  if [[ -z $original_error ]]; then
    "$rm_command" -- "$renamed" || original_error='fixture removal failed'
  fi

  if $simulate_cleanup_failure && $created_namespace; then
    cleanup_error="controlled cleanup failure; residual run $run_id"
  elif $created_namespace && [[ -d $namespace && ! -L $namespace ]]; then
    for fixture_path in "$fixture" "$renamed"; do
      if [[ -e $fixture_path || -L $fixture_path ]]; then
        "$rm_command" -- "$fixture_path" || cleanup_error="residual fixture in run $run_id"
      fi
    done
    verification_remove_namespace "$mountpoint" "$run_id" || cleanup_error="${cleanup_error:+$cleanup_error; }residual run $run_id"
  elif $created_namespace && [[ -e $namespace || -L $namespace ]]; then
    cleanup_error="residual run $run_id is not a removable directory"
  fi
  /sbin/umount "$mountpoint" || cleanup_error="${cleanup_error:+$cleanup_error; }unmount failed for run $run_id"
  rmdir "$mountpoint" 2>/dev/null || cleanup_error="${cleanup_error:+$cleanup_error; }mountpoint remains for run $run_id"

  if [[ -n $original_error ]]; then
    printf 'verification transaction failed for %s: %s\n' "$run_id" "$original_error" >&2
    if [[ -n $cleanup_error ]]; then
      printf 'cleanup also failed; %s\n' "$cleanup_error" >&2
    fi
    return 1
  fi
  if [[ -n $cleanup_error ]]; then
    printf 'cleanup failed; %s\n' "$cleanup_error" >&2
    return 1
  fi
  printf 'verification transaction passed and cleaned: %s\n' "$run_id"
}

collision_check() {
  local auth_file=$1 server=$2 share=$3 run_id=$4
  local mountpoint namespace sentinel collision_output collision_status cleanup_error=''
  mountpoint=$(mktemp -d)
  export VERIFICATION_RUN_ID=$run_id
  verification_validate_run_id "$run_id"
  mount_authenticated "$auth_file" "$server" "$share" "$mountpoint" || {
    rmdir "$mountpoint"
    fail "collision check could not mount verification endpoint"
  }
  namespace="$mountpoint/$run_id"
  sentinel="$namespace/preexisting.txt"
  verification_create_namespace "$mountpoint" "$run_id"
  printf '%s\n' 'preserve me' >"$sentinel"

  set +e
  collision_output=$(transaction "$auth_file" "$server" "$share" "$run_id" false false 2>&1)
  collision_status=$?
  set -e
  [[ $collision_status -ne 0 ]] || cleanup_error='duplicate namespace was accepted'
  [[ $collision_output == *"exclusive namespace creation failed"* ]] ||
    cleanup_error="${cleanup_error:+$cleanup_error; }failure was not caused by duplicate creation"
  [[ $(<"$sentinel") == 'preserve me' ]] || cleanup_error="${cleanup_error:+$cleanup_error; }pre-existing state was modified"

  /bin/rm -- "$sentinel" || cleanup_error="${cleanup_error:+$cleanup_error; }sentinel cleanup failed"
  verification_remove_namespace "$mountpoint" "$run_id" || cleanup_error="${cleanup_error:+$cleanup_error; }collision namespace remains"
  /sbin/umount "$mountpoint" || cleanup_error="${cleanup_error:+$cleanup_error; }collision mount remains"
  rmdir "$mountpoint" 2>/dev/null || cleanup_error="${cleanup_error:+$cleanup_error; }collision mountpoint remains"
  [[ -z $cleanup_error ]] || {
    printf 'collision check failed for %s: %s\ntransaction output: %s\n' \
      "$run_id" "$cleanup_error" "$collision_output" >&2
    return 1
  }
  printf 'duplicate namespace rejected without modifying existing state: %s\n' "$run_id"
}

usage() {
  printf 'usage: %s {collision|expect-denied|transaction} ...\n' "${0##*/}" >&2
  return 2
}

main() {
  local command auth_file server share run_id fail_after_create simulate_cleanup_failure
  command=${1:-}
  shift || true
  case $command in
    collision)
      auth_file=''
      run_id=''
      server=10.10.10.11
      share='homelab-verification$'
      while (( $# )); do
        case $1 in
          --auth-file) auth_file=$2; shift 2 ;;
          --run-id) run_id=$2; shift 2 ;;
          --server) server=$2; shift 2 ;;
          --share) share=$2; shift 2 ;;
          *) usage; return ;;
        esac
      done
      [[ -n $auth_file && -n $run_id ]] || { usage; return; }
      collision_check "$auth_file" "$server" "$share" "$run_id"
      ;;
    expect-denied)
      auth_file=''
      server=10.10.10.11
      share='homelab-verification$'
      while (( $# )); do
        case $1 in
          --auth-file) auth_file=$2; shift 2 ;;
          --server) server=$2; shift 2 ;;
          --share) share=$2; shift 2 ;;
          *) usage; return ;;
        esac
      done
      expect_denied "$auth_file" "$server" "$share"
      ;;
    transaction)
      auth_file=''
      run_id=''
      server=10.10.10.11
      share='homelab-verification$'
      fail_after_create=false
      simulate_cleanup_failure=false
      while (( $# )); do
        case $1 in
          --auth-file) auth_file=$2; shift 2 ;;
          --run-id) run_id=$2; shift 2 ;;
          --server) server=$2; shift 2 ;;
          --share) share=$2; shift 2 ;;
          --fail-after-create) fail_after_create=true; shift ;;
          --simulate-cleanup-failure) simulate_cleanup_failure=true; shift ;;
          *) usage; return ;;
        esac
      done
      [[ -n $auth_file && -n $run_id ]] || { usage; return; }
      transaction "$auth_file" "$server" "$share" "$run_id" "$fail_after_create" "$simulate_cleanup_failure"
      ;;
    *) usage ;;
  esac
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
