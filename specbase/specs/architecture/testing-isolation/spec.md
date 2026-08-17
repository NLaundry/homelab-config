---
id: architecture.testing-isolation
---

### Requirement: The test subject is isolated from its compute provider
**ID:** `test-subject-boundary`
The test execution topology SHALL use the selected execution host only as compute infrastructure and SHALL run candidate systems exclusively as ephemeral guests rather than activating a candidate on that host.

#### Scenario: The physical NAS supplies test compute
**ID:** `builder-remains-compute-only`
- **WHEN** the physical NAS executes a candidate system test
- **THEN** the candidate runs in disposable guests
- **AND** the NAS does not activate the candidate as its own system generation

### Requirement: Test networks are isolated from the physical LAN
**ID:** `test-network-boundary`
Test guests SHALL communicate only through explicitly declared private virtual test networks and SHALL NOT receive an address or route on the physical homelab LAN.

#### Scenario: Multiple test guests communicate
**ID:** `guests-use-private-test-network`
- **WHEN** a test connects two or more guests
- **THEN** they communicate through the test topology
- **AND** neither guest addresses the physical homelab LAN
