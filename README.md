# Channel — Alpine Rootfs

Alpine ARM64 with OpenRC for the Motorola Moto G7 Play.

## Build

Run `rootfs.yml` on the `alpine` branch to produce the rootfs with matching kernel modules.

Output: `rootfs.ext4.zst` (ext4 label: `rootfs`). Boot images are built separately.

## USB SSH

The USB gadget provides `172.16.42.1`:

```sh
ssh root@172.16.42.1
```

## Wi-Fi

From the device shell, use NetworkManager:

```sh
nmcli device wifi list
nmcli --ask device wifi connect "SSID" ifname wlan0
nmcli connection show --active
```

## Time

Set the correct UTC time manually if needed:

```sh
date -u -s "YYYY-MM-DD HH:MM:SS"
date
```

## Expand the root filesystem

On the booted device, as root, identify the partition mounted at `/`:

```sh
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS
grep ' / ' /proc/mounts
command -v resize2fs
```

On Alpine, install `resize2fs` if it is missing:

```sh
apk add e2fsprogs-extra
```

If `/` is ext4, replace the placeholder with **that exact partition**:

```sh
resize2fs /dev/ROOT_PARTITION
df -h /
```

This grows ext4 into available space on its existing partition. Do not run it against a different partition.

## Rootfs details

- Artifact: `rootfs`
- Image: `rootfs.ext4.zst`
- Format: ext4 (raw, zstd-compressed)
- Label: `rootfs`
- UUID: `89530000-6320-4000-8000-000000000001`
