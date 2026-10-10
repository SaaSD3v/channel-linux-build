# Channel — Debian Rootfs

Debian Trixie rootfs for the Motorola Moto G7 Play.

## Build

Run `rootfs.yml` on the `debian` branch. The workflow packages the userspace and modules matching the kernel build.

Output: `rootfs.ext4.zst` (ext4 label: `rootfs`). Boot images are built separately.

## Rootfs image

The workflow produces `rootfs.ext4.zst`, a compressed raw ext4 filesystem. Extract it on the host:

```sh
zstd -d -k rootfs.ext4.zst
```

Use your existing lk2nd boot setup to deploy the rootfs.

After boot, check the root filesystem using `findmnt -n -o SOURCE,FSTYPE /` and `df -h /`. Only if the verified root partition is ext4 and has unused space, use `resize2fs` with the confirmed device path.

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
