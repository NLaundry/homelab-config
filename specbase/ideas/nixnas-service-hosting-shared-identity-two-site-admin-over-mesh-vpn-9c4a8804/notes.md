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