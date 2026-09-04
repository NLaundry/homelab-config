---
id: configuration.ai-gateway-microvm
---

## Purpose

NASty realizes the AI gateway as a bounded microvm.nix guest with a stable direct LAN attachment and explicit ingress policy.

## ADDED Requirements

### Requirement: The guest uses the selected MicroVM runtime
**ID:** `microvm-runtime`
NASty SHALL instantiate `ai-gateway` through the flake-locked microvm.nix QEMU/KVM runtime.

#### Scenario: Production configuration is evaluated
**ID:** `microvm-runtime-is-selected`
- **WHEN** the NASty system configuration is evaluated
- **THEN** the `ai-gateway` guest resolves through the locked MicroVM module and KVM hypervisor

### Requirement: The guest attaches directly to the trusted LAN
**ID:** `macvtap-lan-attachment`
The `ai-gateway` guest SHALL attach through macvtap in `bridge` mode on NASty's `enp2s0` uplink using locally administered MAC address `02:00:00:10:10:20`.

#### Scenario: Guest interface configuration is evaluated
**ID:** `macvtap-interface-is-stable`
- **WHEN** the guest's production interfaces are evaluated
- **THEN** its macvtap parent, mode, and MAC address match the selected values

### Requirement: The guest uses the selected static network values
**ID:** `gateway-network-values`
The `ai-gateway` guest SHALL use `10.10.10.20/24` with gateway and DNS resolver `10.10.10.1`.

#### Scenario: Guest network configuration is evaluated
**ID:** `static-network-matches-selection`
- **WHEN** the guest address, route, and resolver are evaluated
- **THEN** they match the selected trusted-LAN values

### Requirement: The guest has a bounded compute budget
**ID:** `gateway-resource-budget`
The `ai-gateway` guest SHALL be limited to 2 virtual CPUs and 4 GiB of memory.

#### Scenario: Guest resources are evaluated
**ID:** `resource-limits-are-explicit`
- **WHEN** the MicroVM definition is evaluated
- **THEN** both CPU and memory limits match the selected budget

### Requirement: The guest denies unsolicited LAN ingress
**ID:** `gateway-firewall`
The `ai-gateway` firewall SHALL reject unsolicited trusted-LAN ingress until a service change selects an allowed listener.

#### Scenario: LAN client connects to the empty guest
**ID:** `undeclared-port-is-blocked`
- **WHEN** a trusted-LAN test client connects to an undeclared TCP port
- **THEN** the guest firewall rejects the connection
