# Persistent service VM storage

## Convention

Use one private ZFS dataset per persistent service VM:

```text
smolBoy/services/<service>
└── state.img             # Persistent guest filesystem
```

Keep this outside `smolBoy/data`, which is shared through SMB. This convention
is a storage layout, not a VM provisioning or backup framework. Provision each
new dataset/image explicitly; never recreate missing production state at boot.
Nix owns VM configuration; native ZFS owns existing datasets and their mounts.

`smolBoy/services` mounts at `/smolBoy/services`. It has compression `lz4`, atime
off, SMB/NFS sharing off, and host execution, devices and setuid off. Child
datasets inherit these properties. Host `exec=off` does not prevent execution
inside a guest's filesystem image. Preserve normal ZFS sync semantics.

Parent and CA dataset mountpoints are root:kvm mode 0710. The CA image is
microvm:kvm mode 0600. These match the current microvm.nix service identity;
check actual identities for future services rather than assuming a group named
`microvm` exists. Restrict each service's files to its runtime identity.
These datasets inherit the pool's unencrypted storage: permissions and encrypted
key files are not a substitute for disk encryption. In particular, the online
CA volume also contains its runtime decryption identity.

## North York CA

- Dataset: `smolBoy/services/step-ca`.
- Image: `/smolBoy/services/step-ca/state.img`, 4 GiB sparse ext4.
- Filesystem label: `step-ca-state`; guest mountpoint: `/var`.
- Separate encrypted identity recovery file: `guest-identity.age`.
- QEMU/KVM microvm, 1 vCPU, 1024 MiB; host network/storage readiness dependencies.
- Startup checks the exact mounted ZFS dataset and existing image, not merely a
  directory that could be left behind when a dataset is missing.

The migration stopped the VM, copied the image and identity recovery file,
compared both byte-for-byte, and created `@initial-migration`. After deploying the
new path, verified SSH, guest persistent state, one CPU and the running QEMU image
path, the old `/smolBoy/step-ca` copies were removed. Root custody stayed locked.
Old Nix generations refer to the former path: retain the new path when rolling
back configuration, or explicitly restore a stopped image to the expected path.

## Backup and recovery

Use [North York backups](north-york-backups.md) for the operator's weekly and
pre-change independent encrypted CA/router copies, streaming decrypt/hash checks
and isolated recovery. Retain four verified weekly sets and the latest pre-change
copy until the replacement is verified and accepted. Keep a verified copy outside
the NAS failure domain. This is a manual cadence, not a new scheduler or backup
framework.

The CA procedure stops `step-ca.service` for a consistent tar of
`/var/lib/{step-ca,sops-nix,ssh}` while leaving the guest available for SSH. It
records prior active state and restores **only a previously active service**, on
success and failure. It includes the guest age/SSH identities and old private
rollback JSON as well as the intermediate/database; no plaintext archive is
written. Host recovery also needs the persistent NetworkManager profiles, which
Nix does not recreate. See [NAS networking](nas-networking.md).

For an additional local image snapshot, during an approved window:

1. Record `systemctl show -p ActiveState --value microvm@step-ca.service` on NAS;
   refuse a transitioning/unknown state. Confirm guest CA service state as well.
   Before stopping anything, choose the service-level tar procedure instead if
   the CA is deliberately stopped: booting this autostart guest would start it.
2. Stop the VM cleanly and verify QEMU has exited before running
   `sudo zfs snapshot smolBoy/services/step-ca@<reviewed-name>`.
3. Restore **only a previously active VM**, even if snapshot creation failed.
   Verify guest CA state and health. An already stopped VM must remain stopped.
   On recovery failure, retain console access and report failure.

A local snapshot is not independent recovery. A running-image snapshot is at best
crash-consistent, not an application-consistent CA backup. The unencrypted online
dataset contains the runtime decryption identity beside encrypted secrets, so
plain image copies/ZFS streams expose recoverable private material. Do not export
those unencrypted. The independent encrypted tar is the routine recovery copy;
no automatic ZFS replication is configured here.

Restore with the VM stopped. Verify the exact dataset mount, image path/label and
ownership, intermediate identity, guest credentials and native database opening
before accepting startup. Preserve the current `/smolBoy/services/step-ca/state.img`
path when rolling back an older generation; the former path has been removed.
Perform production-key restore drills without NICs or test-network connectivity;
use dummy keys for networked tests. Missing CA state is a recovery condition,
never permission to initialize another authority. A guard pass alone is not proof
of database integrity or successful restore.
