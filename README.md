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

## Alpine utilities

BusyBox can identify the root mount without `findmnt`:

```sh
grep ' / ' /proc/mounts
df -h /
```

Optional packages, installed only when needed:

```sh
apk add e2fsprogs-extra          # resize2fs
apk add android-tools-img2simg  # Android sparse converter (community)
```

The image itself is raw ext4; sparse conversion is not part of the build.

## Rootfs details

- Artifact: `rootfs`
- Image: `rootfs.ext4.zst`
- Format: ext4 (raw, zstd-compressed)
- Label: `rootfs`
- UUID: `89530000-6320-4000-8000-000000000001`
