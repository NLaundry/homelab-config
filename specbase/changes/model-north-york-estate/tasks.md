## 1. Model the current North York Estate

- [ ] 1.1 Rename the `home` site to `north-york`, update NASty's site reference, and preserve its address, storage pools, and file-sharing placement in `estate.yaml`.
- [ ] 1.2 Add the existing OPNsense router, OpenWrt access point, and Proxmox host with their current North York LAN addresses, and record the current North York LAN as `10.10.10.0/24`; add no Scarborough data.

## 2. Replace value-copying Estate enforcement

- [ ] 2.1 Confirm every surviving binding that shares `tests/estate/inventory.bats`, then remove its obsolete site-name assertions without adding North York hosts, addresses, or CIDR expectations; retain only checks still required by unrelated surviving bindings.
- [ ] 2.2 Retire binding `estate-inventory-locations`, remove its direct observation from `tests/specbase/enforcement-observations.json`, and link `inventory-locates-estate` to `estate-inventory-review` using the configured Estate review lens.
- [ ] 2.3 Run the shared inventory Bats source for regression safety and record the command and result in change progress without treating it as evidence of North York's contents.
- [ ] 2.4 Run the Estate review and record its result in change progress.

## 3. Validate the bounded change

- [ ] 3.1 Search tracked Estate consumers for the retired `home` key and update only references that identify this site.
- [ ] 3.2 Review the implementation diff and reject any Ansible, OpenTofu, NetBird, live-network, or unrelated file change.
- [ ] 3.3 Run normal repository and strict Specbase validation and record the results before applying the next stack member.
