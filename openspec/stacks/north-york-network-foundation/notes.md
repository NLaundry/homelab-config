# North York network foundation stack notes

## Goal

Establish reusable North York network infrastructure as code, adopt the North York NetBird control plane, enroll the North York OPNsense router, and activate bounded administrator access to clientless LAN resources.

## Delivery order

1. `model-north-york-estate`
2. `establish-network-secret-operations`
3. `adopt-north-york-netbird-control-plane`
4. `enroll-north-york-opnsense-peer`
5. `activate-north-york-netbird-routing`

Each prefix is independently useful and reversible. The first changes only repository inventory. The second establishes operator custody and bounded secret delivery. The third adopts an intentionally unrouted NetBird baseline. The fourth enrolls OPNsense without advertising the LAN. The fifth crosses the routing boundary only after both control paths are proven.

## Ownership

- `estate.yaml` is the readable current Estate inventory.
- OpenTofu is the sole routine authority for managed NetBird control-plane objects.
- Ansible is the sole routine authority for managed OPNsense package, interface, firewall, and service settings.
- SOPS is the single repository encryption policy for managed credentials.
- Setup keys are one-use runtime material and never belong in SOPS documents or OpenTofu state.

## Deferred scope

This stack does not add Scarborough, DNS, DHCP, root PKI, step-ca, Kanidm, Samba identity changes, application SSO, AdGuard, CoreDNS, Pangolin, or public ingress. A later site stack must add Scarborough by reusing the module and role boundaries established here.

Clientless North York LAN hosts become reachable routed resources, not NetBird peers, and are not automatically enumerated or named.

## Planning overlap

`establish-network-secret-operations` intentionally takes ownership of the shared SOPS/tooling foundation. The unapplied `establish-ai-secret-operations` change must be revised later to consume this foundation rather than creating another root SOPS policy or operator identity convention.

## Validation lifecycle

Every member passes normal planning validation. Projected stack validation is expected to report missing planned enforcement sources until implementation creates the named commands, Bats tests, and runbooks. Strict projected validation is an implementation gate, not a pre-implementation planning claim.
