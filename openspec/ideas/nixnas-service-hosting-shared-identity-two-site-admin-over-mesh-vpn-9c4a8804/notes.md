Goal: host services for multiple people with a SINGLE login, and connect two sites (my house + dad's house) so each side can access the other's infra as ADMINS. Admins and users are separate tiers. (Dad will likely run his own stuff too — how his users relate to my identity realm is unresolved; lean is one IdP with site-scoped groups.)

DECIDED — IDENTITY (Shape A):
- Mesh VPN's own identity (NetBird Cloud, free plan) handles NETWORK ENTRY; kanidm is INTERNAL-ONLY and handles APP SSO. NetBird is an OIDC CONSUMER, not a provider — apps cannot "login with NetBird", so kanidm cannot be replaced by it.
- Two logins on paper: NetBird once per device (silent after), kanidm passkey daily. ACCEPTED tradeoff: zero public exposure, free plan. Deprovisioning = remove in two places (Shape B = custom OIDC, one place to revoke, but requires NetBird Team plan OR Tailscale free + PUBLIC kanidm + webfinger — deferred unless lifecycle unification matters).
- KANIDM IS THE ONLY DIRECTORY. Every layer (netbird policies, pangolin later, apps) is a CONSUMER of kanidm OIDC/groups. No second user store anywhere (never create users inside netbird/pangolin). This invariant is what makes the proxy layer swappable.
- Groups admins/users as the single source, consumed in three places: (1) overlay ACLs (admins -> all tags incl. both sites + ssh; users -> service tags only), (2) forward-auth gateway (oauth2-proxy in front of non-OIDC apps), (3) OIDC group claims to native-SSO apps (grafana, immich, navidrome...).
- Cross-site admin reach via NetBird SSH / mesh (ACL-gated, no ssh-key distribution).
- SSO = identity, NOT full RBAC: per-app authorization stays app-side (jellyfin libraries, immich shared albums).

SERVICE HOSTING MECHANISMS:
- nix-native by default: nspawn containers (containers.XXX wrapping services.XXX) + NixOS modules; podman/OCI ONLY for image-first apps — realistically Booklore today, maybe Audiobookshelf/Immich later (own-cadence via pinned digest; ZFS storage-driver wrinkle is the tax).
- HAOS = full VM (qemu/KVM; microvm.nix can't boot appliance images). Alternative: HA Core as nix service (services.home-assistant) — loses supervisor add-ons.
- Proxy NOW: nginx or caddy + oauth2-proxy (stopgap). Proxy FUTURE: Pangolin (see below).
- Certs: internal-only services; LE wildcard DNS-01 certs for *.lab/*.test.nathanlaundry.com still viable — issuance talks to public DNS provider, resolution stays internal. No app-level public exposure.
- DNS: AdGuard client-facing with wildcard rewrites (*.lab -> proxy, internal only). CoreDNS optional later if per-record authority needed (could be generated from flake registry).
- Observability: prometheus/grafana (+victoriametrics, vector), loki; journald from nspawn containers centralizes logging natively.
- CrowdSec: RETIRED — no public edge when everything rides the overlay.
- Dockhand / portainer-style UIs: dropped (no docker daemon; the flake is the control surface).
- Everything starts on the NixNAS (measure performance); old Proxmox box = future second NixOS compute host (same flake, hosts/<role>/).

PANGOLIN (future proxy layer):
- Replaces nginx/caddy + oauth2-proxy: per-resource access, sessions, better UX. Traefik under the hood (+ Gerbil tunnel daemon, Badger forward-auth) — docker-first (podman tier, pinned digest, own cadence matches its fast release train). Young: beta Jan 2025, v1.18 by mid-2026. Community edition limits: ONE ROLE PER USER; must disable self-signup/org-creation (hardening). NixOS module is WIP.
- Gerbil tunnel = how dad's site services get exposed without him joining the mesh.
- Boundary: NetBird = machine/device layer (mesh, admin SSH, any protocol); Pangolin = human access layer (web apps, sessions, remote-site exposure). Drawn now so they don't fight.

OPEN THREADS:
- Dad's site runs his own stuff: one shared IdP vs island per site? (lean: one IdP + site-scoped groups)
- users tier granularity (family vs friends may need separate tiers later)
- kanidm vs authentik onboarding feel for non-technical people (kanidm lean; authentik if pretty invites win)
- Immich timing; Audiobookshelf nixpkgs status; per-app own-cadence appetite
- Performance deferred — measure when hosting on NixNAS
- Shape A -> Shape B upgrade path: revisit only if one-place deprovisioning becomes worth the cost/exposure
---
## SESSION (explore ~2026-02-13): DNS-first launch plan + two-namespace PKI

REFINE/DECIDE — namespace + PKI split (supersedes the AdGuard/CoreDNS line above):
- TWO namespaces, ONE namespace = issuer, chosen cleanly:
  - laundrylab.tech — real Cloudflare zone, LE-issued wildcard. Humans + unconfigurable devices. Pre-trusted everywhere, zero per-device cert work. (Registrar = Cloudflare; nominal ~$15/yr.)
  - laundrylab.internal — ICANN-reserved (2024) private TLD, step-ca-issued. Machines, exporters, backups, future EAP-TLS Wi-Fi client certs / mTLS. Root CA installed only on hosts you administer.
- .local REJECTED (RFC 6762 mDNS: Apple devices ignore unicast DNS for it). .arpa caveat: bare laundrylab.arpa unavailable (IANA infrastr.); sanctioned form is *.home.arpa. .internal is the short sanctioned option.
- Domain = policy: no per-hostname issuer decisions ever. Browser-facing stays LE even if step-ca is running.
- LE now (trivial), step-ca = the harder learning, so IT GOES FIRST (user prefers learning-first).

SERVICE HOSTING REFINE:
- CoreDNS replaces AdGuard for the authority job (deviation from prior "AdGuard + CoreDNS later" line):
  - CoreDNS = authoritative zone server, real zone file, flake-defined; AdGuard's renames were a bolt-on, and ads can be layered later (client → AdGuard → CoreDNS) or deferred.
  - Runs in a MICROVM (deviation from "nspawn by default") at 10.10.10.5 statically leased — deliberate: DNS is the shared foundation, wanted clean isolation + clean address. Everyone-else hosting stays nspawn default.
  - Cross-site is FREE (single zone file on one server; dad's HisNAS is just an A record pointing at its NetBird IP). Requires DHCP-set resolver per site only; no per-device config.
  - Upgrade path if DNS becomes dynamic/API-managed: PowerDNS (periods REST API, DB-backed, strong DNSSEC). CoreDNS fine now (small surface, flake-native).

EXECUTION PHASES (start DNS-first):
- P0 DNS: CoreDNS microVM 10.10.10.5 = authoritative laundrylab.internal (ns/NASty records, ca/idm CNAMEs) + forward . to upstream; udp+TCP 53; DHCP(OPNsense) advertises 10.10.10.5; NAS self-resolution gotcha. DONE-WHEN: MacBook resolves both internal + internet through 10.10.10.5.
- P1 step-ca: nspawn on NASty; root→cold off-NAS; first leaf = ca.laundrylab.internal (self-signed bootstrap→leaf, restart); root into flake security.pki for hosts + `step ca bootstrap` on MacBook; DONE-WHEN: curl https://ca.laundrylab.internal green from MacBook.
- P2 kanidm experiment: nspawn container, leaf idm.laundrylab.internal; directory basics + posix/unixd on throwaway VM; decide production URL (.internal vs .tech) BEFORE adoption pays OAuth redirect churn.
DEFER: AdGuard ad-block finish; NetBird-site DNS; PowerDNS; EAP-TLS/mTLS (AP-gated); Samba-vs-kanidm users; GID strategy.

TODO (open, unresolved — hits P0): DHCP handling. Don't yet know the DHCP story: who is the DHCP server on each site (OPNsense? existing vs new?), how each site advertises the CoreDNS microVM as resolver, static-lease mechanism for 10.10.10.5, and whether Dad's side hands out NASty's NetBird IP centrally or needs a local resolver. Resolve before wiring P0 so the resolver hand-off is explicit.

---
## SESSION (explore): NetBird routing peers + infrastructure as code

REFINE/DECIDE — routing peer placement:
- Install the official `os-netbird` plugin directly on each OPNsense router where supported (official from OPNsense 25.7.3). Installing NetBird makes OPNsense a peer; assigning it to a NetBird Network makes it that site's routing peer.
- Model North York and Scarborough as separate NetBird **Networks**. Each gets its local LAN/VLAN CIDR resources, its local OPNsense peer/group as the routing peer, and explicit policies. Use the newer Networks model, not deprecated Routes (except if an exit-node-only feature later requires Routes).
- For clientless LAN-to-LAN traffic, add explicit policies in both directions. The sites must use non-overlapping subnets.
- Keep masquerade enabled initially. This removes return-route plumbing and is compatible with OPNsense/FreeBSD; original source-IP visibility is not currently worth a separate Linux routing peer. Revisit only for a concrete auditing, destination-firewall, performance, or plugin-reliability need.
- OPNsense as routing peer removes a dedicated routing VM and a static route from the gateway to that VM. Trade-off accepted provisionally: NetBird becomes part of the firewall's failure/security boundary, and FreeBSD uses NetBird's userspace forwarding path.

DECIDED — configuration ownership:
- Use **OpenTofu** with NetBird's official Terraform provider for NetBird control-plane state: groups, Networks, Network resources, routing-peer assignments (`netbird_network_router`), policies, and later DNS settings where appropriate.
- Import the manually created North York and Scarborough Networks rather than recreating them. Once imported, OpenTofu is authoritative and the NetBird dashboard is for inspection/debugging; avoid routine edits in both places.
- Pin the NetBird provider version because its published support matrix is still immature/TBD.
- Use **Ansible** as the sole configuration owner for the OPNsense machine layer: package/plugin installation, NetBird enrollment/bootstrap, `wt0` assignment, firewall rules, and service settings. Prefer the `oxlorg.opnsense` collection's idempotent modules; use its raw module against official OPNsense or `os-netbird` API endpoints only where a dedicated module is absent.
- Do not use the pre-1.0 community OPNsense Terraform provider for this design. Its incomplete package, NetBird-plugin, and interface-assignment coverage would require overlapping ownership with Ansible.
- Allow one bounded manual bootstrap to create a restricted OPNsense API user/key when required. Afterwards, keep configuration in Ansible and use firewall savepoints plus one-router-at-a-time rollout and connectivity checks for changes that could cause lockout.
- Keep the long-lived NetBird management PAT in **SOPS** and expose it to OpenTofu as `NB_PAT` only during runs. Keep OPNsense API credentials in SOPS and expose them only to Ansible runs. Do not put plaintext secrets in repository configuration.
- Setup keys are short-lived bootstrap credentials: prefer one-use generation → OPNsense enrollment through the `os-netbird` API → immediate revocation/deletion. Avoid managing persistent setup keys through OpenTofu because the plaintext key is recorded in state even when marked sensitive.
- Protect OpenTofu state independently (encrypted storage, strict permissions, no Git). The enrolled peer's long-lived WireGuard/NetBird identity remains local to OPNsense.

---
## SESSION (explore): site-local automatic DNS/DHCP

DECIDED — replace the earlier CoreDNS P0 plan:
- Do not deploy the dedicated CoreDNS microVM at `10.10.10.5` for now. CoreDNS is strong for static file-backed authority but does not discover DHCP clients; its `auto` plugin only reloads zone files.
- Run **OPNsense Dnsmasq as the combined DNS/DHCP service at each site**. Each router owns its local leases and remains usable when the other site or NetBird is unavailable.
- Use one site-specific dynamic subdomain per router, provisionally `ny.laundrylab.internal` and `sc.laundrylab.internal`. Dnsmasq publishes DHCP-provided names and reservation names beneath its local subdomain. Treat dynamic names as convenience, not identity: important machines and services still receive static reservations and declarative records.
- Advertise the local OPNsense resolver through each site's DHCP. Configure conditional forwarding for the other site's dynamic subdomain to the remote OPNsense resolver over NetBird, with explicit UDP and TCP port 53 access.
- Keep stable canonical service names such as `ca.laundrylab.internal` and `idm.laundrylab.internal` in one shared Ansible data set and render the same host aliases/overrides on both routers. This is synchronized desired configuration, not runtime lease or zone replication.
- **Ansible owns both Dnsmasq configurations**, using one reusable role plus site-specific variables. It manages DHCP ranges, reservations, local domain, cross-site forwarding, stable aliases, listener scope, and firewall rules. Never edit generated Dnsmasq files directly.
- **OpenTofu owns NetBird DNS distribution** through `netbird_nameserver_group` resources. NetBird peers receive the relevant split-domain resolvers; ordinary clientless LAN devices continue to use the local OPNsense resolver. Avoid applying NetBird-managed DNS to the OPNsense resolver peers where that could create a forwarding loop.
- NetBird's automatic peer names remain useful for enrolled peers, while OPNsense Dnsmasq supplies names for non-NetBird LAN devices.
- Revisit Technitium or Kea DHCP-DDNS only if a unified dynamic authoritative zone, richer DNS API/UI, or replicated authority becomes a concrete requirement. CoreDNS and PowerDNS are no longer part of the initial deployment.

REVISED P0 DNS:
- Configure Dnsmasq DNS/DHCP on both OPNsense routers through Ansible, including site domains, ranges, reservations, shared service aliases, and cross-site conditional forwarding over NetBird.
- DONE-WHEN: a client at either site resolves local dynamic names, the other site's fully-qualified dynamic names, shared service names, and public internet names through its local OPNsense resolver; a managed NetBird peer resolves the same internal names through OpenTofu-managed NetBird nameserver groups.

OPEN THREADS:
- Confirm both sites' OPNsense versions support `os-netbird` and the required Dnsmasq DNS/DHCP API surface; identify their current DHCP implementations before migration.
- Validate the exact OPNsense API payloads for `os-netbird` settings/enrollment, `wt0` assignment, and Dnsmasq configuration against the installed versions before writing the Ansible roles.
- Choose the final short labels for the two dynamic subdomains (`ny`/`sc` are provisional).
- Define the actual North York and Scarborough LAN/VLAN CIDRs and verify they do not overlap.
- Decide where encrypted OpenTofu state and backups live.

---
## SESSION (explore): proposal-stack boundaries

DECIDED — Stack 1 is North York only:
- Name the first stack **North York network foundation**. Its goal is to establish reusable Estate, SOPS, OpenTofu, and Ansible foundations; adopt North York into NetBird; enroll the North York OPNsense router; and activate it as the routing peer for North York resources.
- Do not add Scarborough to the Estate, Ansible inventory, NetBird Networks, routing, or DNS in Stack 1. A later Scarborough stack must prove that the same IaC modules and roles can add a second site primarily through site-specific data rather than copied implementation.
- Stack 1 has five independently useful prefixes:
  1. `model-north-york-estate` — minimally rename/model the current site as North York and associate the existing infrastructure with it; this is intentionally a tiny `estate.yaml` transition using existing Estate conformance rather than new bespoke enforcement.
  2. `establish-network-secret-operations` — establish the repository's shared SOPS tooling and operator workflow, encrypt NetBird and OPNsense credentials, define ephemeral injection boundaries, and provide a runbook for the required human bootstrap. This proposal may supersede overlapping secret-tooling assumptions in the unapplied AI stack; reconcile that stack later instead of creating a second SOPS convention now.
  3. `adopt-north-york-netbird-control-plane` — establish the OpenTofu root/provider/state workflow and create or import only North York groups, Network, resources, and policies. The Network deliberately has no routing peer yet.
  4. `enroll-north-york-opnsense-peer` — use Ansible to install/configure `os-netbird`, consume a one-use setup key, enroll OPNsense, assign `wt0`, and verify a healthy peer. Enrollment alone does not advertise or route the LAN.
  5. `activate-north-york-netbird-routing` — use OpenTofu to assign the enrolled OPNsense peer/group as the North York Network router, enable masquerading, activate explicit admin policies, and verify bounded access to selected North York resources.
- After Stack 1, OPNsense appears as a NetBird peer and North York LAN resources are reachable through it. Clientless LAN hosts do not become NetBird peers and are not automatically enumerated; individual named resources must be declared in OpenTofu where policy needs them, and friendly host resolution remains deferred to DNS.
- Keep OpenTofu authoritative for the NetBird control plane and Ansible authoritative for OPNsense. Never let both tools own the same remote object or router setting.

DEFERRED — later stacks:
- Stack 2 will establish North York naming and private trust. Expected order: offline root authority → North York Dnsmasq DNS/DHCP → NetBird DNS distribution → online step-ca intermediate → managed root-trust distribution. DNS details remain under exploration and are not part of Stack 1.
- A separate Scarborough stack will add the second site with the reusable Estate schema, OpenTofu modules, and Ansible roles produced by Stack 1, then add site-local DNS and cross-site forwarding.
- Kanidm, managed-host identity, Samba migration, web SSO, application hosting, AdGuard, CoreDNS, and Pangolin remain outside Stack 1.
