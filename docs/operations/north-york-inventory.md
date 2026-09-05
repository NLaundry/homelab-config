# Confirm the North York inventory

## What

Check that `estate.yaml` describes the current site. This step changes only
documentation, not a host or network.

## Why

Later operations need correct addresses and placement. An inventory cannot prove
its own accuracy; compare it with the devices and local network records.

## Steps

### 1. Confirm the site facts

1. Confirm the North York LAN is `10.10.10.0/24`.
2. Confirm each device's management address:

   | Device | Address |
   |---|---|
   | OPNsense | `10.10.10.1` |
   | OpenWrt AX23 | `10.10.10.2` |
   | Proxmox | `10.10.10.10` |
   | NASty | `10.10.10.11` |

3. Confirm that NASty hosts file sharing and holds `mediaBin` and `smolBoy`.

### 2. Update the inventory

1. Put each host under `north-york.hosts`. Put services under their host or VM.
2. Do not add proposed devices, empty VMs, or Scarborough entries.

## Check

Read the diff:

```sh
git diff -- estate.yaml
```

Confirm the facts, not just the YAML spelling. An inventory edit does not update
NixOS, Ansible, DHCP, or the devices themselves. Update operational configuration
separately when an actual address or service changes.

## Stop or recover

Stop if the inventory disagrees with the site. Confirm the correct value before
continuing. Correct a mistaken entry with a normal edit; do not change a device
to make it match an unverified inventory value.

## Source

[Archived estate change](../../openspec/changes/archive/2026-09-04-model-north-york-estate/).
The current nested inventory replaces the archived flat layout and inventory test.
