# Enforcement: nixpkgs is pinned to a NixOS release with a committed lock

Paired with `spec.md` (`ops.nixpkgs-pin`). The pin is proven by inspecting
`flake.nix`'s input URL and `flake.lock`'s resolved rev, and the flake evaluating
cleanly against the lock. Ops flavor: lockfile audit + plan/eval validate.

```yaml
version: 1
spec: ops.nixpkgs-pin
bindings:
  - id: flake-input-pins-release
    covers: [nixpkgs-release-pinned, flake-input-pins-release]
    mechanism: command
    strength: automated
    status: active
    targets:
      - flake.nix
    run:
      command: grep
      args: [-q, "nixos-26.05", flake.nix]
      cwd: .
    limitations: Proves the nixpkgs input references the nixos-26.05 channel; the "NixOS release, not unstable" rule is asserted by the paired spec.

  - id: lock-committed-pinned
    covers: [nixpkgs-release-pinned, lock-committed-pinned]
    mechanism: command
    strength: automated
    status: active
    targets:
      - flake.lock
    run:
      command: git
      args: [ls-files, --error-unmatch, flake.lock]
      cwd: .
    limitations: Proves flake.lock is tracked; the resolved-rev content is asserted by the paired spec and visible in the file.

  - id: flake-evaluates-against-pin
    covers: [nixpkgs-release-pinned, flake-evaluates-against-pin]
    mechanism: command
    strength: automated
    status: active
    targets:
      - flake.lock
    run:
      command: nix
      args: [flake, check]
      cwd: .
    limitations: Proves the flake evaluates against the lock; does not prove the resulting closure boots on the NAS.
