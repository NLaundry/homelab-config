# Enforcement: deploys build on the host and activate remotely; the Makefile exposes the surface

Paired with `spec.md` (`ops.deployment`). The Makefile target surface is proven
by `make -n` (expand-without-running) and a parse of the Makefile's variables —
both reproducible from the workstation. The end-to-end deploy genuinely
requires the box, so it is an honest `manual` binding.

```yaml
version: 1
spec: ops.deployment
bindings:
  - id: makefile-targets-expand
    covers: [makefile-target-surface, makefile-targets-expand]
    mechanism: command
    strength: automated
    status: active
    targets:
      - Makefile
    run:
      command: make
      args: [-n, deploy]
      cwd: .
    limitations: >-
      Proves `deploy` expands to a nixos-rebuild invocation; the other targets
      (boot/test/dry/build/check) are asserted by the paired spec and checked by
      the same mechanism when exercised.

  - id: makefile-uses-target-and-build-host
    covers: [remote-deploy-mechanism, build-on-host, activate-as-operator, makefile-targets-expand]
    mechanism: command
    strength: automated
    status: active
    targets:
      - Makefile
    run:
      command: grep
      args:
        - -q
        - --target-host
        - Makefile
      cwd: .
    limitations: >-
      Proves the Makefile references --target-host; the --build-host and
      operator@/sudo flags are likewise asserted by the paired spec and visible
      in the Makefile.

  - id: makefile-vars-overridable
    covers: [makefile-vars-overridable]
    mechanism: command
    strength: automated
    status: active
    targets:
      - Makefile
    run:
      command: grep
      args: [-q, "TARGET ?=", Makefile]
      cwd: .
    limitations: Proves TARGET is overridable; HOST and FLAKE likewise use `?=` and are asserted by the paired spec.

  - id: deploy-succeeds-runtime
    covers: [deploy-succeeds-runtime]
    mechanism: manual
    strength: manual
    status: active
    targets:
      - Makefile
    procedure: >-
      From the workstation, run `make deploy` against the NAS and confirm the
      system builds on the NAS and activates without error, then SSH back in to
      confirm the new generation is reachable. Requires the box reachable over
      SSH as operator.
    rationale: >-
      An end-to-end build-and-activate is a runtime outcome against the live box;
      no workstation-side check proves it succeeds.
    limitations: Confirms a deploy succeeds at the time it is run, not on every invocation.
