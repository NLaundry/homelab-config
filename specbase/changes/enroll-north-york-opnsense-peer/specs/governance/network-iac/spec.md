---
id: governance.network-iac
---

## ADDED Requirements

### Requirement: OPNsense configuration authority is singular
**ID:** `opnsense-configuration-authority`
The repository SHALL use Ansible as the routine change authority for managed OPNsense package, interface, firewall, and service configuration.

#### Scenario: Managed OPNsense setting changes
**ID:** `managed-opnsense-change-uses-ansible`
- **WHEN** an operator changes a managed OPNsense machine setting
- **THEN** the change is declared and reconciled through the repository Ansible path rather than an OpenTofu OPNsense resource

### Requirement: OPNsense automation is reusable by site
**ID:** `opnsense-automation-reusable`
The OPNsense automation SHALL separate reusable router behavior from site-specific inventory and values.

#### Scenario: North York router is configured
**ID:** `north-york-consumes-shared-role`
- **WHEN** the North York OPNsense play is resolved
- **THEN** it consumes the shared router role with North York data and no embedded second-site implementation
