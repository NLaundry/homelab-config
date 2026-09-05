## Context

`estate.yaml` currently contains one generic `home` site and only the NAS, while `ansible/inventory.yml` already identifies the current router, access point, Proxmox host, and NAS by their North York addresses. Later Stack 1 members need one canonical site key and complete current-site host references before introducing IaC ownership.

## Goals / Non-Goals

**Goals:**
- Name the existing site `north-york`.
- Catalogue the four existing managed hosts and the `10.10.10.0/24` LAN boundary.
- Preserve current service and storage placement.
- Keep the change data-only and review its contents without duplicating them in enforcement.

**Non-Goals:**
- Add Scarborough or speculative future-site records.
- Change Ansible inventory, addresses, DNS, routing, or live systems.
- Introduce a new Estate schema or validation framework.

## Decisions

- Modify the existing `estate.model` pair because its current scenario explicitly names the `home` site; a new site-specific pair would duplicate the inventory's data rather than state a reusable invariant.
- Replace the pair's value-copying test binding with the configured Estate review lens. The shared Bats source remains for other current pairs, but its hardcoded `home` assertion is removed rather than replaced with hardcoded North York values.
- Use `north-york` as the stable machine key and `North York` as the human name.
- Catalogue existing devices under neutral host keys (`opnsense`, `ax23`, `proxbox`, and `nas`), retain the addresses already used by operational inventory, and record `10.10.10.0/24` as the current North York LAN consumed by later route policy.
- Keep practical product and connection details out of this change; later configuration proposals own those choices.

## Enforcement design

The configured `estate` review lens becomes the sole binding for `inventory-locates-estate`. Review compares the proposed inventory with the known managed Estate and rejects missing, speculative, or mislocated entries. This is honest judgment rather than a second copy of the YAML values; it does not prove that devices are online.

`tests/estate/inventory.bats` is a shared source for other surviving governance, storage, and configuration bindings. This change removes only its obsolete assertion that the site key is `home`; it does not add North York value assertions or claim that source as Estate-model evidence.

## Risks / Trade-offs

- [Renaming `home` can leave stale references] -> Search tracked Estate consumers and update the single canonical key atomically.
- [Inventory data can differ from physical reality] -> Reuse addresses already present in `ansible/inventory.yml`; live reconciliation remains outside this data-only change.
- [Adding all known devices slightly expands the tiny change] -> Keep fields limited to site, hostname, and current LAN address.

## Migration Plan

1. Rename the site key and update NASty's site reference.
2. Add the existing router, access point, and Proxmox host.
3. Replace the Estate model's test binding with Estate review and remove obsolete site-name assertions from the shared Bats source after confirming its unrelated bindings survive; add no North York content assertions.
4. Run the remaining shared harness checks for regression safety and normal Specbase validation.
5. Roll back by reverting this data-only commit; no live state is affected.
