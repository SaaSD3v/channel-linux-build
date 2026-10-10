# Channel — Ubuntu Rootfs

Ubuntu Base ARM64 rootfs for the Motorola Moto G7 Play.

## Build

Run `rootfs.yml` on the `ubuntu` branch. Kernel modules come from the matching build.

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

## Optional Android sparse tools

The rootfs build produces raw ext4. Use these tools only if you need to convert a copy of the image, not as a new flashing step.

Install the sparse tools on Ubuntu if you need them:

```sh
sudo apt install android-sdk-libsparse-utils
```

After decompressing `rootfs.ext4.zst`:

```sh
img2simg rootfs.ext4 rootfs-sparse.img
simg2img rootfs-sparse.img rootfs-restored.ext4
```

The first command converts raw to sparse; the second converts sparse back to raw. No conversion is required for the existing lk2nd workflow.

## Rootfs details

- Artifact: `rootfs`
- Image: `rootfs.ext4.zst`
- Format: ext4 (raw, zstd-compressed)
- Label: `rootfs`
- UUID: `89530000-6320-4000-8000-000000000001`
