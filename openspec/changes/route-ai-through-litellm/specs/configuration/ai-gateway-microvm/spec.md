---
id: configuration.ai-gateway-microvm
---

## MODIFIED Requirements

### Requirement: The guest admits only the LiteLLM listener
**ID:** `gateway-firewall`
The `ai-gateway` firewall SHALL admit trusted-LAN TCP traffic only to port 4000.

#### Scenario: Unexpected LAN listener is attempted
**ID:** `undeclared-port-is-blocked`
- **WHEN** a trusted-LAN test client connects to a TCP port other than 4000
- **THEN** the guest firewall rejects the connection
