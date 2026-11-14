# Block storage and mounts

## Identifying a target

Use `lsblk` and filesystem signatures, mount information and `/dev/disk/by-id` to identify a device. Before any destructive write, verify the resolved device, model, serial, size, existing partitions, signatures and mounts; device names can change. If the disk is not enumerated, investigate connection, power and kernel logs rather than presenting a mount as ready.

```bash
lsblk -b -o NAME,PATH,SIZE,TYPE,FSTYPE,LABEL,UUID,MOUNTPOINTS,MODEL,SERIAL,TRAN
blkid
findmnt
ls -l /dev/disk/by-id /dev/disk/by-label /dev/disk/by-uuid
journalctl -k -b -g 'usb-storage|uas|SCSI disk|I/O error|disconnect'
```

Use elevated access where needed to see signatures; a missing disk cannot be mounted until it is enumerated.

Mount an existing filesystem separately from formatting. For Btrfs, subvolumes are not partitions; qgroups provide subvolume capacity limits. Clarify conflicting requested names before creating a layout.

## Guarding destructive operations

Formatting requires explicit authorization for the identified target. A blank-disk formatter should refuse existing child partitions, mounted devices and holders; show signatures using `wipefs --no-act`, require an explicit target-specific confirmation, and fail on failed checks. Inspect every external command including optional branches and verify availability on the execution host before handing off a runnable script. Verify the resulting mounts and filesystem state; perform a small write/read/delete check when appropriate.

For a runnable script, check all commands, including optional branches, with `command -v`. `sgdisk` (gptfdisk) and `partprobe` (parted) may be missing; `sfdisk` and `blockdev --rereadpt` are possible util-linux alternatives, but check their availability and the intended operation. Wait for udev after a partition-table refresh with `udevadm settle`. An optional fstab change belongs in the initial invocation or a separate operation.

Do not advise rerunning a successful formatter to add an fstab entry: the existing partition should make a blank-disk guard refuse. Include that option in the initial operation or use a separate non-formatting operation after verifying filesystem identity.

## Busy devices and hidden mounts

A host `findmnt`, `lsof` or `fuser` view can miss mounts in another process's mount namespace. Compare the device major:minor with `/proc/<pid>/mountinfo` and inspect a candidate namespace with `nsenter`. A rootless container pause process can retain a mount after containers disappear; verify the relevant empty scope before stopping it. Do not force past an exclusive-use failure: identify and release the holder. A partition-table reread is relevant after changing a partition table, not a prerequisite for every format.

A stale container-storage configuration pointing at a retired mount can later recreate state on the wrong filesystem; update the configuration as part of migration.
