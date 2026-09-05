# Auth & Identity Concepts — a homelab glossary

A reference for the concepts and acronyms that came up while exploring user
management. Organized from the abstract ("what is an identity") down to the
concrete ("what is tdbsam"). Not a tutorial — a map. Cross-reference the
exploration in the parent folder's `notes.md` (Shape A) for how these land in
*this* homelab.

---

## 1. Core concepts (the mental model)

### Identity vs credential vs directory
- **Identity** — *who* someone is (a person, a service). An identity is a
  durable record with attributes: name, email, groups, uid/gid, etc.
- **Credential** — *proof* of an identity. A password, an SSH key, an NT hash,
  a Kerberos ticket, a WebAuthn passkey. Credentials are secrets bound to an
  identity; an identity can have many of them. Crucial framing for this
  homelab: SSH keys and samba passwords are **credentials**, not a second
  user store. The identities behind them live in one directory.
- **Directory** — the *store* of identities (and sometimes their credentials).
  "Kanidm is the only directory" means: only kanidm decides who *exists*.
  Per-protocol credential stores (smbpasswd, authorized_keys) are keyed to
  those identities but don't define new ones.

### Identity Provider (IdP)
- **IdP / Identity Provider** — a service that holds identities and vouches for
  them to other services. Kanidm, Keycloak, Authentik, Authelia are IdPs. The
  IdP is the *source of truth* for "who are the users and what groups are they
  in."
- **Relying Party (RP) / consumer** — a service that *trusts* an IdP's vouching
  instead of holding its own users. Navidrome trusting kanidm for logins =
  Navidrome is a consumer. **NetBird is a consumer, not a provider** — apps
  cannot "log in with NetBird," which is exactly why NetBird cannot replace
  kanidm.

### Single Sign-On (SSO)
- **SSO** — log in once (to the IdP), access many apps without re-authenticating.
  SSO is about *identity*, **not** authorization: the IdP says "this is Alice,"
  but *which Jellyfin libraries Alice can see is decided by Jellyfin*, not the
  IdP.

### Authorization vs authentication
- **Authentication (AuthN)** — proving who you are.
- **Authorization (AuthZ)** — what you're allowed to do. Per-app RBAC (Jellyfin
  libraries, Immich shared albums) stays app-side even under SSO.

### RBAC, tiers, deprovisioning
- **RBAC (Role-Based Access Control)** — permissions assigned to *roles/groups*
  rather than individuals. Grant "write" by joining the `smb-writers` group.
- **Tier** — a coarse authorization level. In this homelab: read, read/write,
  admin (and possibly family/friends split later).
- **Deprovisioning** — removing a user's access. The cost question: does
  revoking Alice touch one place (one directory) or several (directory + smb
  password + ssh key + ...)? Shape A accepts two-place SMB deprovisioning as
  the price of no public exposure.

---

## 2. Authentication protocols & mechanisms

### OIDC / OAuth2 (the web-app stack)
- **OAuth 2.0** — a delegation framework: let app A access user's stuff on
  service B without the user giving A their password. RFC 6749.
- **OIDC (OpenID Connect)** — built *on top of* OAuth 2.0 to add **login**
  ("who is this user?") via an `id_token`. OAuth alone is about *access*;
  OIDC adds *identity*. Apps "log in with kanidm" via OIDC.
- **There is no "OIDC 2.0"** — verified against the OpenID Foundation
  (mid-2026): the core standard remains **OpenID Connect Core 1.0** (with
  approved errata). The "2.0" floating around that ecosystem is **FAPI 2.0**,
  a stricter *security profile* layered on OIDC 1.0 for banking-grade flows
  — not a new version of OIDC itself. Don't wait for an OIDC 2.0; implement
  against 1.0. (The confusion comes because OAuth *underneath* is "2.0", and
  people stack "OAuth 2.0 + OIDC" and assume OIDC inherits the 2.0. It
  doesn't: OIDC 1.0 sits on top of OAuth 2.0.)
- **Relying Party (RP)** — see §1; in OIDC, the app consuming tokens.
- **Client Credentials Grant** — machine-to-machine OIDC: a service authenticates
  as itself (with a client secret/key), not on behalf of a user. How a service
  reads from another service.
- **Scope / claim** — a scope is a requested permission (`openid`, `email`,
  `groups`); a claim is the data returned in the token (`groups: [admins]`).
  Kanidm maps groups → OIDC group claims.

### LDAP (the directory-access protocol)
- **LDAP** — a protocol for *querying and modifying* a directory. RFC 4511.
- **LDAPS** — LDAP over TLS (port 636). Kanidm exposes LDAP, **read-only**.
- **Simple bind** — LDAP auth by sending a DN + password. Kanidm supports it.
- **ldapsam / smbpasswd-backed-by-LDAP** — a samba passdb backend that reads
  user entries from LDAP instead of a local file. **Open spike**: does kanidm
  hold the samba-specific password attributes samba needs, given its LDAP is
  read-only? Likely no → tdbsam stays a parallel credential store.

### Kerberos & KDC (the file-access/enterprise stack)
- **Kerberos** — a ticket-based auth protocol where a trusted **KDC (Key
  Distribution Center)** issues tickets clients present to services. The only
  practical way to get per-user cryptographic NFSv4 auth (`sec=krb5`).
- **Realm** — a Kerberos administrative domain (e.g. `EXAMPLE.COM`).
- **Keytab** — a file holding a service's Kerberos key; the service uses it to
  decrypt client tickets.
- **⚠️ kanidm has NO built-in KDC.** Verified: kanidm's supported features are
  OAuth2/OIDC, LDAP (read-only), RADIUS, PAM/NSS, Webauthn, TOTP, SCIM — **no
  Kerberos**. Kerberos is an *open feature request* (kanidm#1614, motivated
  by secure NFSv4 home dirs). So Kerberized NFS would require a *separate* KDC
  (MIT Kerberos / FreeIPA / AD), breaking the "kanidm is the only directory"
  invariant. **Keycloak and Authentik also have no KDC** — they can federate
  to one, not host one.

### RADIUS
- **RADIUS** — a network-access auth protocol (VPNs, WiFi EAP, switches).
  Kanidm supports MSCHAPv2 and EAP-TLS. Relevant if a service (e.g. a WiFi
  AP) needs to authenticate against the directory.

### PAM / NSS / unixd (the POSIX-integration stack)
- **PAM (Pluggable Authentication Modules)** — Linux's login stack. "Can this
  password log this user in?" goes through PAM.
- **NSS (Name Service Switch)** — Linux's "who is uid 1005?" lookup. `getpwnam`
  / `getgrnam` go through NSS.
- **unixd (`kanidm_unixd`)** — kanidm's client daemon that wires kanidm into
  PAM + NSS. **This is the pivot**: with unixd, kanidm users become *real
  POSIX users on the NAS* (real uid/gid, real groups). Samba then resolves
  its users via NSS to kanidm — no `force user` hack needed. Also caches
  users/groups + credentials for offline login (TPM-backed), and auto-creates
  home directories via its tasks daemon.
- **SSH key distribution (`kanidm_ssh_authorizedkeys`)** — kanidm stores SSH
  public keys *on the user account* in the directory, and hosts fetch them at
  login time by configuring sshd's `AuthorizedKeysCommand` to call
  `kanidm_ssh_authorizedkeys`. Cached via unixd so login still works during a
  kanidm outage. **This is how kanidm feeds the OS-admin layer** — sshd keys
  no longer have to be hardcoded per-host in `default.nix`.

### WebAuthn / Passkeys / TOTP
- **WebAuthn** — the standard behind passkeys / security keys (FIDO2). Strong,
  phishing-resistant. Kanidm supports WebAuthn level 3.
- **Passkey** — a WebAuthn credential, often sync'd across devices (Apple/
  Google passkeys). "kanidm passkey daily" from the notes.
- **TOTP** — time-based one-time codes (RFC 6238), the classic 6-digit
  authenticator-app code. Kanidm supports it as a second factor.

---

## 3. File & network-access specifics

### SMB / CIFS
- **SMB (Server Message Block) / CIFS** — the Windows/Mac file-sharing
  protocol. macOS Finder is SMB-first; the `fruit`/`streams_xattr` Samba VFS
  modules in this repo exist specifically for Finder metadata.
- **Guest share** — a share reachable without credentials (current NAS state).
- **`force user` / `force group`** — Samba options that run *every* guest
  connection as a fixed POSIX identity. The current hack: guests become
  `operator` so RW works on operator-owned datasets. Cost: zero accountability.
- **`valid users` / `write list` / `admin users`** — Samba access control by
  user/group. `write list` overrides a read-only share for listed users;
  `admin users` grants root-like power on the share. Groups resolve via NSS.
- **Passdb backend** — where Samba stores its account credentials:
  - **tdbsam** — a local TDB (trivial database) file. The simple default.
  - **ldapsam** — backed by LDAP (see spike in §2).
  - **smbpasswd** — legacy flat-file format (avoid).
- **NTLMv2** — the auth handshake Samba actually uses; it wants an **NT hash**
  in its passdb. Kanidm stores Argon2ID, not NT hashes — the reason samba
  almost certainly needs its own parallel credential store even with kanidm
  POSIX users.

### NFS
- **NFS** — the Unix file-sharing protocol. Two flavors that matter:
  - **`sec=sys`** — server trusts the client's *claimed* UID/GID + an export IP
    list. No real auth; "anyone on the LAN is trusted." Lateral move from
    guest SMB, not an upgrade in accountability.
  - **`sec=krb5`** — per-user cryptographic auth via Kerberos tickets. Real
    accountability, but **requires a KDC** (which kanidm lacks — see §2).
- Decision in this homelab: **stay on SMB**; macOS-first clients + no kanidm
  KDC make NFS the harder path for *less* benefit.

---

## 4. Network & VPN

- **Mesh VPN** — a VPN where every node talks to every other node directly,
  peer-to-peer, without a central relay for traffic. NetBird, Tailscale.
- **NetBird** — the chosen mesh VPN (Cloud free plan). Handles *network entry*
  — a device joins the mesh and can reach other mesh nodes per ACLs.
- **Overlay** — the virtual network the mesh creates on top of the physical
  LAN/internet. "Everything rides the overlay" = no services need public
  exposure; they're reached via the mesh.
- **ACL (Access Control List, mesh sense)** — in NetBird, per-tag rules
  (`admins → all tags incl. both sites + ssh`; `users → service tags only`).
  These are *network* ACLs, not file ACLs — different plane.
- **NetBird vs kanidm boundary** — NetBird = machine/device layer (mesh,
  admin SSH, any protocol); kanidm = human identity layer. NetBird is an
  OIDC *consumer* of kanidm; it does not hold human users.

---

## 5. Components in this homelab's stack

- **Kanidm** — the chosen IdP. The *only* directory of human identities.
  Speaks MULTIPLE protocols so it can serve every layer, not just web apps:
  OIDC (apps + NetBird), PAM/NSS + SSH-key distro (POSIX hosts), read-only
  LDAP, RADIUS, WebAuthn, TOTP, SCIM sync. No Kerberos/KDC, no native samba
  password attrs. The multi-protocol reach is what makes the "one directory"
  invariant actually hold — kanidm isn't *only* an OIDC server.
- **IAM (Identity and Access Management)** — the *umbrella term* for the whole
  discipline, not a single component. Kanidm isn't "an IAM" — it's the IdP,
  one piece. Your IAM is the *combination* of kanidm (identity) +
  oauth2-proxy/Pangolin (app enforcement) + samba `valid users` (file policy)
  + NetBird ACLs (network policy) + per-app RBAC. No single tool covers all
  four layers; a homelab IAM is necessarily federated across tools.
- **Keycloak** — alternative IdP (Java, heavyweight, AD-grade). Considered and
  *not* chosen; buys nothing for SMB/NFS (no KDC either). Can federate to a
  KDC via SPNEGO if one ever exists.
- **Authentik / Authelia** — lighter alternative IdPs. Authentik noted for
  nicer onboarding invites for non-technical family; deferred. **Key
  tradeoff vs kanidm**: Authelia is web/SSO-first and has **no PAM/NSS** —
  it cannot make its users real POSIX users on the NAS, so the SMB
  accountability pivot would need a *separate* POSIX source (a real LDAP or
  plain local users), re-introducing the second user store kanidm avoids.
  Authentik sits closer to kanidm on directory strength. Pick Authelia only
  if app-SSO UX matters more than unifying file/OS identity.
- **NetBird** — mesh VPN; OIDC consumer of kanidm; ACL source for network entry.
- **oauth2-proxy** — a forward-auth gateway placed in front of *non-OIDC*
  apps to give them SSO. Stopgap proxy layer.
- **Pangolin** — future proxy layer (per-resource access, sessions,
  remote-site exposure via Gerbil tunnel). Replaces nginx/caddy + oauth2-proxy
  later. Beta; NixOS module WIP.
- **nginx / caddy** — current reverse proxy in front of internal services.
- **unixd** — kanidm's PAM/NSS client; makes kanidm users real POSIX users.
- **tdbsam** — Samba's local credential store; the parallel credential store
  for SMB passwords keyed to kanidm identities.

---

## 6. Tiers & accounts (how users are organized)

- **OS admin** — currently `operator` (hardcoded in `default.nix`, SSH key +
  passwordless sudo). *Future state*: `operator` (and other admins) become
  kanidm POSIX users; SSH keys fetched from kanidm via
  `kanidm_ssh_authorizedkeys`; `wheel`/sudo membership driven by a kanidm
  group (`homelab-admins`). **Not OIDC** — this layer talks to kanidm via
  PAM/NSS + SSH-key distribution, not tokens. A minimal local break-glass
  admin likely stays for the "kanidm is down" recovery case.
- **Network entry** — per-device/person in NetBird, sourced from kanidm
  groups. Tiers: admins (all tags + both sites + ssh), users (service tags).
- **App login** — human identities in kanidm. SSO = identity, not RBAC;
  per-app authorization stays app-side.
- **File access (SMB)** — the track this exploration landed on. Tiers via
  kanidm groups consumed by samba through NSS: `smb-readers`, `smb-writers`,
  `smb-admins`.
- **Service / system users** — *not* humans. (a) NixOS system users, one per
  service, owning their files; (b) OIDC client credentials for
  machine-to-machine. These live alongside kanidm as clients/service-accounts,
  not in the human login flow.
- **Guest** — unauthenticated access. Open decision: keep *any* guest surface
  (e.g. a read-only media share) or go fully authenticated.

---

## 7. The four-layer mental model (the thing that resolves the confusion)

A homelab has four mostly-independent identity layers, each with its own auth
mechanism — and **the IdP speaks a different protocol to each**, not OIDC to
all of them. The earlier version of this diagram drew lines only from the
OIDC-using layers and left OS admin disconnected. That conflated *OIDC* (one
protocol) with *kanidm* (the directory, which speaks several). Corrected:

```
  ┌─────────────┐ ┌───────────────┐ ┌────────────┐ ┌──────────────────┐
  │ OS admin    │ │ Network entry │ │ File access│ │ App login (SSO)  │
  │ SSH + sudo  │ │ mesh VPN      │ │ SMB        │ │ Navidrome/etc    │
  ├─────────────┤ ├───────────────┤ ├────────────┤ ├──────────────────┤
  │ PAM/NSS +   │ │ OIDC consumer │ │ Samba creds│ │ OIDC consumer    │
  │ SSH key     │ │ (NetBird)     │ │ + NSS uid  │ │ native or proxy  │
  │ distro      │ │               │ │  lookup    │ │                  │
  │             │ │               │ │            │ │                  │
  │ ✅ via PAM/ │ │ ✅ via OIDC   │ │ ⚠ creds    │ │ ✅ via OIDC      │
  │   NSS, NOT  │ │               │ │   local,   │ │                  │
  │   OIDC      │ │               │ │   id via NSS│ │                  │
  └──────┬──────┘ └───────┬───────┘ └─────┬──────┘ └────────┬─────────┘
         │ PAM/NSS         │ OIDC          │ NSS            │ OIDC
         │ + SSH keys      │               │ (uid/gid)      │
         └─────────────────┼───────────────┼────────────────┘
                           │               │
                  ┌────────▼───────────────▼────────┐
                  │         kanidm (the IdP)         │
                  │  speaks MULTIPLE protocols:      │
                  │   • OIDC    → apps + NetBird     │
                  │   • PAM/NSS → POSIX hosts        │
                  │   • SSH key distro → sshd        │
                  │   • LDAP (read-only)             │
                  │   • RADIUS                       │
                  │  ONE user store, many protocols  │
                  └──────────────────────────────────┘
```

### Per-layer protocol table

| Layer | Talks to kanidm via | What kanidm provides |
|---|---|---|
| OS admin | PAM/NSS + SSH-key distro | Real POSIX users, sshd-fetchable keys, `wheel` from a kanidm group |
| Network entry (NetBird) | OIDC | User identity + group claims for ACLs |
| File access (SMB) | NSS (uid/gid) + local NT-hash creds | POSIX identity so samba can `getpwnam`; samba password stays in tdbsam |
| App login | OIDC (native SSO or oauth2-proxy) | `id_token` + group claims |

**Three of four layers now directly consume kanidm.** Only SMB keeps a
parallel credential store, and even there the *identity* comes from kanidm
via NSS. That's much more unified than "OIDC touches two layers" suggested.

### Provisioning a new host (pull, not push)

Bringing a new VM/machine into the identity realm is **not** "create the
users on the new host." It's **"make the new host trust kanidm for who
exists."** The users appear on the host *on first login* — home dir
auto-created by unixd-tasks, SSH keys fetched from kanidm, PAM auth against
kanidm. Concretely (per kanidm docs):

1. Install `kanidm-unixd-clients` on the new host.
2. Configure `/etc/kanidm/unixd` and `/etc/kanidm/config` (point at the
   kanidm server, set the realm).
3. Enable `kanidm_unixd` + `kanidm_unixd_tasks` services.
4. Add `kanidm` to `/etc/nsswitch.conf` **before** `files`/`compat` so NSS
   resolves kanidm users first.
5. Wire PAM (`kanidm` module) for auth.
6. Set sshd `AuthorizedKeysCommand` to `kanidm_ssh_authorizedkeys`.
7. Declare which kanidm groups are allowed to log in to this host.
8. Ensure POSIX attributes are enabled on the kanidm accounts.

In a Nix flake, steps 1-7 become a `services.kanidm` client module imported
into the host's `default.nix` — so **any host you build automatically gets
all kanidm users + keys + groups on first login.** No per-host user
declaration. Deprovisioning inverts the same way: remove someone from
`homelab-admins` in kanidm → they lose SSH + sudo on *every* host at once.

**Bootstrap/recovery caveat**: the *first* host still needs a local
break-glass admin, because you can't SSH to kanidm to fix kanidm if kanidm
is down. A minimal local `operator` (or rescue user) likely stays even after
kanidm takes over everyday admin logins.