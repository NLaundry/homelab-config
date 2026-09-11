#!/usr/bin/env python3
"""Protect external commissioned state; optionally assemble one private JWE field.

Never initialize authority/database state or read the rollback config/ca.json.
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
import tempfile


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


def encrypted_payload(path):
    # Presence, size bound and private permissions only. Payload shape and
    # decryption belong to the existing operator, not to this guard.
    required_file(path, "operator-payload-missing", private=True)
    require(path.stat().st_size <= 65536, "operator-payload-invalid")
    value = path.read_text().strip()
    require(bool(value), "operator-payload-invalid")
    return value


def assemble(state, public_config, payload_mode, runtime_config=None):
    cfg = read_json(pathlib.Path(public_config), "public-config-invalid")
    try:
        provisioners = cfg["authority"]["provisioners"]
        require(isinstance(provisioners, list) and all(isinstance(p, dict) for p in provisioners),
                "public-config-invalid")
        require(all("encryptedKey" not in p for p in provisioners), "public-config-private-field")
        operators = [p for p in provisioners if p.get("type") == "JWK"
                     and p.get("name") == "laundrylab-admin"]
        require(len(operators) == 1, "operator-identity")
    except (KeyError, TypeError):
        raise Refusal("public-config-invalid") from None
    if payload_mode == "none":
        require(runtime_config is None, "runtime-mode")
        require(not (pathlib.Path(state) / "secrets/operator-encrypted-key").exists(),
                "unexpected-operator-payload")
        return  # Native module executes its immutable JSON directly.
    require(payload_mode == "required" and runtime_config is not None, "runtime-mode")
    operators[0]["encryptedKey"] = encrypted_payload(pathlib.Path(state) / "secrets/operator-encrypted-key")
    target = pathlib.Path(runtime_config)
    require(target.parent.is_dir() and not target.parent.is_symlink()
            and stat.S_IMODE(target.parent.stat().st_mode) == 0o700, "runtime-permissions")
    # Write atomically with 0600, including on restart. Never touch persistent JSON.
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=target.parent, delete=False) as stream:
            temporary = pathlib.Path(stream.name)
            json.dump(cfg, stream)
        os.replace(temporary, target)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("state", "trusted_root", "password_file", "openssl"):
        parser.add_argument(name)
    parser.add_argument("--commission", action="store_true")
    parser.add_argument("--mount")
    parser.add_argument("--public-config")
    parser.add_argument("--payload-mode", choices=("required", "none"))
    parser.add_argument("--runtime-config")
    args = parser.parse_args()
    try:
        require(not args.commission or not args.public_config, "runtime-mode")
        check(args.state, args.trusted_root, args.password_file, args.openssl,
              commissioning=args.commission, mount=args.mount)
        if args.public_config:
            require(args.payload_mode is not None, "runtime-mode")
            assemble(args.state, args.public_config, args.payload_mode, args.runtime_config)
        else:
            require(args.payload_mode is None and args.runtime_config is None, "runtime-mode")
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
