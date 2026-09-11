# Runbook: First-time zpool import on the NAS

**Host:** `nasty` (10.10.10.11)
**When to use:** The NAS holds pre-existing ZFS pools with data we want to keep. This runbook covers the *one-time* import and the values we need to make import declarative (`networking.hostId`, pool names). After this is done once and captured in the Nix config, boot-time import is automatic and you never repeat this.

> ⚠️ **Data-preservation rule:** These pools contain real data. **Never** run `zpool create`, `zpool labelclear`, `wipefs`, `sgdisk`, or `dd` against `/dev/sd[a-d]*`. We are *importing*, not creating. If a command wants to destroy or overwrite, stop.

---

## 0. Context: what we already know

The four spinning disks each show a `part1` (data) + `part9` (8 MB reserve) layout — the ZFS whole-disk signature. They were previously members of one or more pools.

```
sda 1.8T ┐             sdc 3.6T ┐
sdb 1.8T ┘ 2×2TB pair  sdd 3.6T ┘ 2×4TB pair
nvme0n1  = boot / root / nix / swap  (NOT a pool member)
```

---

## 1. Inspect before touching anything (read-only)

### 1.1 List importable pools

List importable pools without importing them:

```bash
zpool import
```

### 1.2 Read labels and record pool details

Read the on-disk ZFS label for each data partition (pool name, vdev membership, host that created it):

```bash
sudo zdb -l /dev/sda1
sudo zdb -l /dev/sdb1
sudo zdb -l /dev/sdc1
sudo zdb -l /dev/sdd1
```

**Record from the output:**
- Pool name(s) — e.g. `tank`, `fast`, etc. → needed for `boot.zfs.extraPools`.
- `hostid` / `hostname` fields on the label — tells us whether this box created the pools.
- vdev topology (mirror vs stripe) — sanity-check it matches the 2×2TB / 2×4TB expectation.

### 1.3 Record the current host ID

Also grab the box's current host ID — this is the value for `networking.hostId`:

```bash
hostid
```

> If `hostid` matches the label's hostid, the pools import cleanly with no `-f`. If it differs, the first import needs `-f` (step 3) and we set `networking.hostId` to the value we want to standardize on going forward.

---

## 2. Import (read-only trial first)

### 2.1 Import read-only and check health

Do a read-only import first to confirm the pool is healthy before mounting anything writable. Replace `<pool>` with the real name from step 1.

```bash
sudo zpool import -o readonly=on -N <pool>
zpool status <pool>
zfs list -r <pool>
```

- `-N` = import without auto-mounting datasets yet.
- Confirm `state: ONLINE` and no `DEGRADED` / `FAULTED` vdevs.

### 2.2 Export the trial

Export the read-only trial before the real import:

```bash
sudo zpool export <pool>
```

---

## 3. Real import

### 3.1 Import the pool

```bash
sudo zpool import <pool>
```

If — and only if — import is refused because the pool was last used by another system (message mentions it "was last accessed by another system" / hostid mismatch), force it once:

```bash
sudo zpool import -f <pool>
```

### 3.2 Verify the import

Verify:

```bash
zpool status
zfs list
```

Repeat steps 2–3 for each pool discovered in step 1.

---

## 4. Capture the values for the Nix config

Fill these into `hosts/nas/zfs.nix` (see the config change; not created by this runbook):

```nix
networking.hostId = "<hostid from step 1>";   # 8 hex chars
boot.supportedFilesystems = [ "zfs" ];
boot.zfs.extraPools = [ "<pool1>" "<pool2>" ];
```

Once `extraPools` is deployed, NixOS imports these pools at every boot via a systemd import service — this runbook does not need to run again.

---

## 5. Post-import sanity

```bash
zpool status -v        # no errors, all vdevs ONLINE
zfs get mountpoint -r <pool>   # confirm datasets mount where expected
```

If any dataset has `mountpoint=legacy`, it needs an explicit `fileSystems` entry in Nix (revisit deferred decision **D5**, dataset mountpoint strategy). Native mountpoints mount automatically.

---

## Troubleshooting

| Symptom | Cause | Action |
|---|---|---|
| `pool was last accessed by another system` | hostid mismatch | one-time `zpool import -f <pool>` (step 3) |
| pool not listed by `zpool import` | ZFS module not loaded | `modprobe zfs`, confirm `boot.supportedFilesystems` includes `zfs` |
| dataset didn't mount | `mountpoint=legacy` | add `fileSystems` entry, or `zfs set mountpoint=/path <ds>` |
| pool `DEGRADED` | a disk dropped | **do not** proceed with writes; investigate the failing disk first |

---

## Do NOT

- ❌ `zpool create ...` (this destroys the existing pool)
- ❌ `wipefs` / `sgdisk` / `dd` on `/dev/sd[a-d]`
- ❌ `zpool import -fF` (rewind) unless you fully understand the data-loss tradeoff
