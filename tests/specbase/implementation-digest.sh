#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$ROOT"

{
	printf '%s\n' Makefile flake.nix flake.lock
	find hosts nix specbase/specs -type f -print
	printf '%s\n' specbase/config.yaml
	find tests -type f ! -path 'tests/specbase/evidence/*.json' -print
	find .pi/prompts -maxdepth 1 -type f -name 'spcb-*.md' -print
	find .pi/skills -type f -path '.pi/skills/specbase-*/*' -print
} | LC_ALL=C sort -u | while IFS= read -r file; do
	[[ -f $file ]] || continue
	printf '%s\0' "$file"
	sha256sum "$file"
done | sha256sum | awk '{print $1}'
