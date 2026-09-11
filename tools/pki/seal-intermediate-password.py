#!/usr/bin/env python3
"""Operator-only password entry; writes only SOPS ciphertext, never plaintext."""
import getpass
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]


def seal(password, destination):
    result = subprocess.run(
        ["sops", "--config", str(ROOT / ".sops.yaml"), "--encrypt",
         "--input-type", "json", "--output-type", "yaml",
         "--filename-override", "secrets/step-ca.yaml", "/dev/stdin"],
        input=json.dumps({"intermediate_password": password}).encode(),
        capture_output=True, cwd=ROOT,
    )
    if result.returncode or not result.stdout.startswith(b"intermediate_password: ENC["):
        raise RuntimeError("SOPS encryption failed; no password file written")
    with os.fdopen(os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "wb") as file:
        file.write(result.stdout)


def main():
    if not sys.stdin.isatty():
        raise RuntimeError("Run interactively in the operator terminal; no piped password input")
    destination = ROOT / "secrets/step-ca.yaml"
    if destination.exists():
        raise RuntimeError("Ciphertext already exists; refusing to replace it")
    password = getpass.getpass("Existing intermediate-key password (not the root or provisioner password): ")
    if not password or password != getpass.getpass("Confirm intermediate-key password: "):
        raise RuntimeError("Passwords empty or unequal; nothing written")
    destination.parent.mkdir(mode=0o700, exist_ok=True)
    seal(password, destination)
    print("Encrypted password saved to secrets/step-ca.yaml")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print("Password sealing failed. Check terminal, confirmation, tools and destination; private output withheld.", file=sys.stderr)
        sys.exit(1)
