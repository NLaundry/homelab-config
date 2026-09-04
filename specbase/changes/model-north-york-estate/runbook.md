# User runbook: model North York Estate

## Why you are needed

This change records physical facts that repository automation cannot independently prove. It changes no live system.

## When to act

### Before Tasks 1.1–1.2: confirm the inventory

Confirm that the intended current-site facts are correct:

- Site key: `north-york`
- Site name: `North York`
- OPNsense router: `10.10.10.1`
- OpenWrt AX23 access point: `10.10.10.2`
- Proxmox host: `10.10.10.10`
- NASty: `10.10.10.11`
- North York LAN: `10.10.10.0/24`
- File sharing remains hosted by NASty
- NASty still owns pools `mediaBin` and `smolBoy`
- No Scarborough host or placeholder should appear

If any name or address is wrong, stop and provide the corrected non-secret value before implementation continues.

### At Task 2.4: review the resulting Estate

Review the `estate.yaml` diff as a human-readable inventory. Confirm that it describes the actual North York site rather than merely satisfying a test. The Estate review should reject:

- a missing current device
- a speculative future device
- a wrong site assignment or address
- any Scarborough entry

### Before Task 3.2: approve the prefix

Confirm that the change only updates repository inventory/specification and contains no Ansible, OpenTofu, NetBird, or live network mutation.

## Evidence to record

Record only: reviewer name, date, accepted site key, and whether all listed facts were confirmed. No credentials or device configuration exports are needed.
