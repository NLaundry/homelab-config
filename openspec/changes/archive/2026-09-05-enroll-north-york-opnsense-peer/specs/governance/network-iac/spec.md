---
id: governance.network-iac
---

## ADDED Requirements

### Requirement: OPNsense NetBird authority is singular
**ID:** `opnsense-configuration-authority`
The repository SHALL use Ansible as the routine change path for managed OPNsense NetBird plugin settings while OpenTofu remains the NetBird cloud-control authority.

#### Scenario: A managed OPNsense NetBird setting changes
**ID:** `managed-opnsense-change-uses-ansible`
- **WHEN** an operator changes a managed OPNsense NetBird plugin setting
- **THEN** the change is reconciled through the repository Ansible playbook rather than an OpenTofu OPNsense resource or direct configuration-file edit
