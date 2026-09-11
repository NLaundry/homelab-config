# NAS networking

## Current owner

NixOS enables NetworkManager. Connection settings are persistent NetworkManager
profiles, not generated resolver-file edits. Since 2026-09-07, `nasty-bridge`
(UUID `29bdf7d4-9373-4c59-b854-df4921d8f761`) owns `br-lan`. Its physical port
`nasty-bridge-port` (UUID `c072ce6f-2197-4985-87ab-0b76eece7392`) owns `enp2s0`.
The OPNsense reservation preserves `10.10.10.11` for MAC `c8:ff:bf:01:1f:12`.
The old `Wired connection 1`, UUID `b031f41a-038a-3065-a434-d7c2b136ecff`, is
retained unchanged as recovery fallback (autoconnect priority -999). Both bridge
profiles autoconnect at priority 100. Do not activate the old profile routinely.

## DNS policy

Use OPNsense `10.10.10.1` for DNS. Keep IPv4 DHCP and IPv6 automatic addressing,
but ignore automatically supplied DNS on both protocols. This prevents the
OpenWrt AP's former IPv6 DNS advertisement from becoming an alternate resolver
that blocks private names. DNS transported over IPv4 can still return IPv6
records; this policy does not disable IPv6.

Applied with operator approval on 2026-09-07, on the NAS:

```sh
sudo nmcli connection modify uuid b031f41a-038a-3065-a434-d7c2b136ecff \
  ipv4.dns '10.10.10.1' ipv4.ignore-auto-dns yes \
  ipv6.dns '' ipv6.ignore-auto-dns yes
sudo nmcli device reapply enp2s0
```

Reapply succeeded without disconnecting the interface. Separate SSH verification
confirmed `.11`, gateway `.1`, resolver `.1`, working private/public system DNS,
active `samba-smbd`, and synchronized time. Both address methods remain `auto`.
The old IPv6 DNS entry had already expired before this persistent correction.
This does not establish IPv6 internet connectivity or repair other clients.

Inspect without changing anything:

```sh
nmcli -f ipv4.method,ipv4.dns,ipv4.ignore-auto-dns,ipv6.method,ipv6.dns,ipv6.ignore-auto-dns \
  connection show nasty-bridge
nmcli -f IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.DNS device show br-lan
getent ahostsv4 nasty.ny.laundrylab.internal
getent ahostsv4 example.com
```

Historical undo for the old, now inactive physical profile only (not the bridge;
do not run this as bridge recovery):

```sh
sudo nmcli connection modify uuid b031f41a-038a-3065-a434-d7c2b136ecff \
  ipv4.dns '' ipv4.ignore-auto-dns no \
  ipv6.dns '' ipv6.ignore-auto-dns no
sudo nmcli device reapply enp2s0
```

Do not bounce the interface as an automatic fallback if reapply fails. Inspect
the error while retaining management access. The deployed bridge carries forward
the explicit resolver policy and NAS MAC/reservation, with recovery below.

## Bridge activation and recovery

The operator approved the transition and confirmed local recovery access. Host
and guest builds, 13 CA guard tests and a disposable native HTTPS/database test
passed before activation. Host deployment passed all three deployment Bats tests.
The actual NetworkManager 1.56.0 accepted both bridge profiles in offline preview.

The live transition used a 180-second NetworkManager checkpoint with rollback
flags deleting new connections and disconnecting new devices. A separate SSH
connection verified `.11`, bridge MAC, gateway/DNS `.1`, physical-port membership,
private/public DNS and active SMB before enabling autoconnect and destroying the
checkpoint. IPv6 addressing remains automatic and has acquired fresh addresses;
this is not proof of IPv6 internet access. No NAS reboot was performed. The root
custody dataset remained unmounted with its key unavailable.

MicroVM alone owns `tap-step-ca`, attached to `br-lan`. The guest acquired its
reservation `.12`; verified SSH works both directly from the Mac and through the
NAS. Initial direct SSH timed out; subsequent direct connection passed. Guest
`/var` is the dedicated ext4 image, and its DNS and time synchronization passed.
CA private state is now commissioned and the service is running with root storage
locked. Authorized issuance and off-LAN acceptance remain separate pending checks.
The image now resides in the dedicated `smolBoy/services/step-ca` dataset; see
[service VM storage](service-vm-storage.md).

Local-console recovery, if needed (disconnects the CA guest from LAN):

```sh
sudo systemctl stop microvm@step-ca.service
sudo nmcli connection modify nasty-bridge connection.autoconnect no
sudo nmcli connection modify nasty-bridge-port connection.autoconnect no
sudo nmcli connection down nasty-bridge
sudo nmcli connection up uuid b031f41a-038a-3065-a434-d7c2b136ecff
```

Verify `.11`, resolver/gateway `.1`, SSH and SMB afterwards. Preserve IPv6 and
OPNsense DHCP/DNS ownership; do not start another DHCP server.

## Host reconstruction and recovery SSH

A NixOS rebuild does not recreate these persistent NetworkManager profiles.
Include the root-owned files under `/etc/NetworkManager/system-connections` in
independently encrypted host recovery custody. Preserve the bridge, physical
port and retained fallback UUIDs above; do not publish profile contents because
other NetworkManager profiles may contain credentials.

On an isolated replacement host or through local-console recovery:

1. Restore the verified profile files with root ownership and mode `0600`.
2. Run `sudo nmcli connection reload` to load them without activating a profile.
3. Inspect `nasty-bridge` and `nasty-bridge-port`: preserved UUIDs, MAC, port
   membership, IPv4 DHCP, IPv6 automatic addressing and explicit router DNS.
4. Only with recovery access, activate the approved bridge profile. Verify `.11`,
   gateway/resolver `.1`, independent SSH, private/public DNS and SMB before
   starting the CA guest. Do not activate the old physical profile at the same
   time as the bridge.

Temporary NAS password/root SSH access remains an explicit recovery exception.
Retire it only after named-operator key access and an independent console/profile
restore path are verified, in a separately approved hardening change. This stack
refactor does not change that SSH policy or transfer profile ownership away from
NetworkManager.

## Deferred: Mac hostname SSH stall

On 2026-09-07, Nathans-MBP resolved `nasty.ny.laundrylab.internal` to
`10.10.10.11` through both router DNS and macOS system lookup. Direct-IP SSH
worked, but hostname SSH intermittently hung or reported `Undefined error: 0`.
IPv4 alone was insufficient; the operator repeatedly connected successfully
with `ssh -4 -o ConnectTimeout=5 operator@nasty.ny.laundrylab.internal`.

The Mac's `~/.ssh/config` now scopes `AddressFamily inet` and `ConnectTimeout 5`
to this exact hostname. Its host key was separately compared against the trusted
IP connection and accepted under the DNS name. No HostKeyAlias or weakened host
verification is required. These settings are a workaround, not a diagnosis.
The assistant's execution context did not reproduce the terminal's failures.
Investigate the default versus finite-timeout connection path later; do not
attribute this to DNS, IPv6 or host-key trust without further evidence.
The operator explicitly deferred this investigation. During CA checks, Xcode
Python and Nix step-cli HTTPS calls also returned `No route to host`, while
native curl verified the same endpoint successfully. Record these as additional
client-dependent failures, not proof that they share the SSH issue's cause. Guest-to-LAN access remains
unwanted; do not change firewall isolation to resolve this client issue.
