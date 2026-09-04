---
id: configuration.ai-gateway-microvm
---

## MODIFIED Requirements

### Requirement: The guest admits only selected AI listeners
**ID:** `gateway-firewall`
The `ai-gateway` firewall SHALL admit trusted-LAN TCP traffic only to ports 4000 and 7331.

#### Scenario: Unexpected LAN listener is attempted
**ID:** `undeclared-port-is-blocked`
- **WHEN** a trusted-LAN test client connects to a TCP port other than a selected AI listener
- **THEN** the guest firewall rejects the connection
