# Manual Specbase verification sources

These procedures preserve the live-system evidence formerly embedded in legacy enforcement Markdown. They are intentionally not presented as automated checks.

## pools-import-on-boot-runtime

After a normal NAS boot, run `zpool status` on the NAS. Confirm that `smolBoy` and `mediaBin` are both imported without `-f` and report `ONLINE`. Record the date and observed pool state.

## operator-ssh-sudo-runtime

From the operator workstation, run `ssh -i ~/.ssh/id_ed25519 operator@10.10.10.11 'sudo whoami'`. Confirm key authentication succeeds without a login password and the command prints `root` without a sudo password prompt.

## test-store-kvm-runtime

From the operator workstation, run `nix build --store "ssh-ng://operator@10.10.10.11?ssh-key=$HOME/.ssh/id_ed25519&system-features=kvm%20nixos-test" --eval-store auto --no-link --rebuild .#checks.x86_64-linux.vm-harness-private-network -L`. Confirm the NixOS test starts both QEMU guests with forced acceleration, both guests reach `multi-user.target`, and the private-network assertions and peer pings pass. Record the date, store URI without secret material, and result.

**Attestation — 2026-08-17:** The command above completed successfully against `ssh-ng://operator@10.10.10.11` using derivation `/nix/store/rd700da8llqpp709ixasf5kcl5ba63qh-vm-test-run-harness-private-network.drv` and produced `/nix/store/3j7fshg6pzc7jx7j05wb4j4fv5nqcz36-vm-test-run-harness-private-network`. Because the runner sets `qemu.forceAccel = true`, both QEMU guests starting and reaching `multi-user.target` attest KVM availability. Each guest exposed only `testnet0` with its declared `192.168.250.0/24` address and route, had no default route or route to `10.10.10.1`, reached its peer by ping, and was terminated during successful cleanup.

## deploy-succeeds-runtime

From the operator workstation, run `make deploy` against the NAS. Confirm the build and activation complete successfully, then reconnect over SSH and confirm the activated generation is reachable. Record the generation and verification date.
