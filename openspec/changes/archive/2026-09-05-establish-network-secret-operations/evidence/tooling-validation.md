# Tooling validation

Date: 2026-09-05

Command:

```sh
make test-tooling
```

Result: PASS (5/5).

The check evaluated and built the development shell for `aarch64-darwin` and `x86_64-linux`. It also confirmed that the selected repository commands resolve from Nix and that the Darwin SSH adapter and pinned Specbase command work.
