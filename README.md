# Channel — Debian Rootfs

Debian Trixie rootfs for the Motorola Moto G7 Play.

## Build

Run `rootfs.yml` on the `debian` branch. The workflow packages the userspace and modules matching the kernel build.

Output: `rootfs.ext4.zst` (ext4 label: `rootfs`). Boot images are built separately.

## USB SSH

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

## Rootfs details

- Artifact: `rootfs`
- Image: `rootfs.ext4.zst`
- Format: ext4 (raw, zstd-compressed)
- Label: `rootfs`
- UUID: `89530000-6320-4000-8000-000000000001`
