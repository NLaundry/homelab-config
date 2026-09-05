# SOPS policy validation

Date: 2026-09-05

Command context:

```sh
nix develop --no-update-lock-file
sops --encrypt --config "$PWD/.sops.yaml" \
  --filename-override "$PWD/secrets/network.yaml" DUMMY_INPUT
sops --decrypt DUMMY_CIPHERTEXT
```

Result: PASS.

- The repository contains one root `.sops.yaml`.
- The exact `secrets/network.yaml` policy selected the declared public recipient.
- The intended operator identity decrypted dummy ciphertext.
- An unrelated generated identity was rejected.
- No live credential values were introduced.
- The temporary dummy fixture was removed. A fresh fixture will be generated for the recovery drill in Task 4.4.

Declared public recipient:

```text
age1ppln4es2zdwhk2rjdfv848dckh9nd5c58t39m4345pjmnads9cksg48dsu
```
