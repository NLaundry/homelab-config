#!/usr/bin/env python3
# Validate the commissioned CA state before step-ca starts; never initialize or assemble configuration.
"""Protect the external commissioned step-ca state.

Never initialize authority/database state or assemble runtime configuration.
Failure categories are fixed strings: neither private input nor tool output is logged.
"""
import argparse
import hashlib
import json
import os
import pathlib
import stat
import subprocess
import sys


class Refusal(Exception):
    pass


def require(condition, category):
    if not condition:
        raise Refusal(category)


def required_file(path, category, private=False):
    require(path.is_file() and path.stat().st_size > 0, category)
    if private:
        require(not path.is_symlink() and path.stat().st_mode & 0o077 == 0,
                "private-permissions")


def required_credential(path):
    required_file(path, "password-missing")
    metadata = path.lstat()
    require(stat.S_ISREG(metadata.st_mode), "private-permissions")
    if metadata.st_mode & 0o077 == 0:
        return  # Ordinary private files retain their existing permission rules.

    # Native LoadCredential files can expose a group-read ACL mask. This exception
    # is confined to the explicitly supplied credential directory, never secrets.
    directory = os.environ.get("CREDENTIALS_DIRECTORY")
    require(bool(directory), "private-permissions")
    parent = pathlib.Path(directory)
    require(parent.is_absolute() and ".." not in parent.parts
            and ".." not in path.parts and path.absolute().parent == parent,
            "private-permissions")
    require(stat.S_IMODE(metadata.st_mode) == 0o440
            and metadata.st_uid == 0 and metadata.st_gid == 0, "private-permissions")
    directory_metadata = parent.lstat()
    require(stat.S_ISDIR(directory_metadata.st_mode)
            and directory_metadata.st_uid == 0 and directory_metadata.st_gid == 0
            and directory_metadata.st_mode & 0o027 == 0, "private-permissions")


def read_json(path, category):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        raise Refusal(category) from None


def check(state, trusted_root, password_file, openssl, commissioning=False, mount=None):
    state = pathlib.Path(state)
    if mount is not None:
        require(os.path.ismount(mount), "state-mount")
    require(state.is_dir(), "state-missing")
    root = state / "certs/root_ca.crt"
    crt = state / "certs/intermediate_ca.crt"
    key = state / "secrets/intermediate_ca_key"
    for path in (root, crt, key):
        required_file(path, "authority-file-missing", private=path == key)
    required_credential(pathlib.Path(password_file))
    pem = key.read_bytes()
    encrypted_pkcs8 = pem.startswith(b"-----BEGIN ENCRYPTED PRIVATE KEY-----")
    header = pem.split(b"\n\n", 1)[0]
    encrypted_ec = (pem.startswith(b"-----BEGIN EC PRIVATE KEY-----")
                    and b"Proc-Type: 4,ENCRYPTED" in header and b"DEK-Info:" in header)
    require(encrypted_pkcs8 or encrypted_ec, "unencrypted-intermediate")

    def crypto(*args):
        result = subprocess.run([openssl, *map(str, args)], capture_output=True, check=False)
        require(result.returncode == 0, "crypto-validation")
        return result.stdout

    expected_root = crypto("x509", "-in", trusted_root, "-outform", "DER")
    require(crypto("x509", "-in", root, "-outform", "DER") == expected_root, "root-identity")
    crypto("verify", "-CAfile", trusted_root, crt)
    cert_key = crypto("x509", "-in", crt, "-pubkey", "-noout")
    private_key = crypto("pkey", "-in", key, "-passin", "file:" + str(password_file), "-pubout")
    require(cert_key == private_key, "intermediate-key-mismatch")
    fingerprint = hashlib.sha256(crypto("x509", "-in", crt, "-outform", "DER")).hexdigest()
    if commissioning:
        require(not (state / "commissioned.json").exists(), "already-commissioned")
        require(not (state / "db").exists() or not any((state / "db").iterdir()),
                "existing-database")
    else:
        record = read_json(state / "commissioned.json", "commission-record")
        require(record == {"backend": "badgerv2", "intermediate_sha256": fingerprint},
                "commissioned-identity")
        required_file(state / "db/MANIFEST", "database-manifest")
        require(any(p.is_file() and p.stat().st_size > 0 for p in (state / "db").glob("*.sst")),
                "database-tables")
    return fingerprint


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("state", "trusted_root", "password_file", "openssl"):
        parser.add_argument(name)
    parser.add_argument("--commission", action="store_true")
    parser.add_argument("--mount")
    args = parser.parse_args()
    try:
        check(args.state, args.trusted_root, args.password_file, args.openssl,
              commissioning=args.commission, mount=args.mount)
        print("CA state checks passed" if not args.commission else "First commissioning prerequisites passed")
    except Refusal as exc:
        print(f"CA state check failed [{exc}]; no initialization attempted.", file=sys.stderr)
        return 1
    except OSError:
        print("CA state check failed [state-io]; no initialization attempted.", file=sys.stderr)
        return 1
    except Exception:
        print("CA state check failed [internal-error]; no initialization attempted.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
