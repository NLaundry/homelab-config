## Purpose

Configure the installed OPNsense NetBird plugin as the site's routing peer while keeping NetBird control-plane resources under OpenTofu ownership.

## ADDED Requirements

### Requirement: Configure or explicitly bootstrap the NetBird peer

Ansible SHALL configure the installed OPNsense NetBird plugin. When the target plugin exposes a supported enrollment API, an explicit bootstrap SHALL be able to use a setup key delivered through the secret mechanism. When it does not, the playbook SHALL stop with a clear manual-enrollment prerequisite and SHALL NOT report enrollment success.

#### Scenario: Enroll through a supported plugin API

- **WHEN** an operator runs the explicit NetBird bootstrap with a valid setup key and the plugin exposes the supported enrollment operation
- **THEN** OPNsense enrolls the router as a NetBird peer and applies the requested base plugin settings

#### Scenario: Plugin enrollment is not automatable

- **WHEN** the installed plugin does not expose a supported enrollment operation
- **THEN** the playbook reports that one-time enrollment must be completed manually and does not claim that the peer is registered

### Requirement: Configure site routing behavior

Ansible SHALL configure the approved NetBird routing settings and the OPNsense firewall rule needed for the router to forward the site's LAN through the overlay. NetBird networks, groups, policies, and router resources SHALL remain controlled by OpenTofu.

#### Scenario: Apply routing configuration

- **WHEN** an enrolled peer is present and the operator applies the desired routing configuration
- **THEN** OPNsense saves the requested LAN-routing settings and firewall rule without changing NetBird control-plane resources

#### Scenario: Repeat an unchanged routing run

- **WHEN** the enrolled peer's owned settings and firewall rule already match the desired values
- **THEN** the playbook makes no configuration change

### Requirement: Leave routed behavior to live verification

Ansible SHALL fail on rejected plugin or firewall operations but SHALL NOT treat saved settings or service status as proof that an off-LAN client can reach a routed service.

#### Scenario: Configuration succeeds

- **WHEN** OPNsense accepts the routing configuration
- **THEN** the live verification suite separately checks peer connectivity, route selection, policy behavior, and a real routed service connection
