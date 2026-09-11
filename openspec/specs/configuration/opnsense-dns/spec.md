# opnsense-dns Specification

## Purpose

Provide a small, repeatable configuration path for OPNsense Dnsmasq DNS and DHCP without turning routine Ansible runs into a migration or acceptance framework.

## Requirements

### Requirement: Configure site Dnsmasq service

Ansible SHALL configure the approved site DNS listeners, DHCP behavior, domain, and upstream behavior on OPNsense. Initial service activation or resolver handoff SHALL be explicit rather than an implicit side effect of a routine run.

#### Scenario: Apply initial Dnsmasq configuration

- **WHEN** an operator runs the explicit Dnsmasq bootstrap with approved site values
- **THEN** OPNsense saves the requested Dnsmasq configuration, enables the intended service, and applies the resulting service configuration

#### Scenario: Preview Dnsmasq changes

- **WHEN** an operator runs the Dnsmasq playbook in Ansible check mode
- **THEN** the playbook reports the configuration changes without changing OPNsense

### Requirement: Manage owned DNS and DHCP records

Ansible SHALL manage the approved static reservations, DHCP ranges, and domain overrides by stable operator-defined identities. Omitting an unrelated OPNsense record from the desired data SHALL NOT delete it.

#### Scenario: Create or update an owned reservation

- **WHEN** an owned reservation is absent or differs from the desired address, name, or client identity
- **THEN** the playbook creates or updates that reservation without changing unrelated records

#### Scenario: Repeat an unchanged run

- **WHEN** the desired Dnsmasq records already match OPNsense
- **THEN** the playbook makes no configuration change

### Requirement: Fail on rejected configuration writes

Ansible SHALL fail when OPNsense rejects a requested Dnsmasq or firewall configuration operation. A successful Ansible run SHALL describe configuration operations only and SHALL NOT claim that client DNS, DHCP, or network access has been accepted.

#### Scenario: OPNsense rejects a write

- **WHEN** a Dnsmasq, firewall, or service operation returns an error
- **THEN** the playbook fails and does not report the operation as successful

#### Scenario: Configuration succeeds but behavior is unverified

- **WHEN** the playbook completes its requested configuration operations
- **THEN** behavioral acceptance remains the responsibility of the live verification suite
