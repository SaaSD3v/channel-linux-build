# Channel Linux Build

Mainline Linux for the Motorola Moto G7 Play (`channel`).

## Workflows

The `main` branch hosts the integrated build and component launchers.

The `debian`, `ubuntu` and `alpine` branches each provide a standalone `rootfs.yml`. The `kernel-mainline-7.1`, `dtbo` and `lk2nd` branches build the corresponding boot components.

Run the desired workflow from **Actions**. A rootfs workflow can reuse a compatible kernel build.

## Output

The integrated workflow publishes the Debian rootfs, kernel boot image, DTBO and lk2nd. Standalone rootfs builds publish `rootfs.ext4.zst`; the kernel workflow publishes `boot-channel.img` and matching modules.

Kernel source: [SaaSD3v/linux](https://github.com/SaaSD3v/linux), `msm8953/latest`.

## USB SSH

Connect the host to the USB gadget at `172.16.42.1`:

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

If `resize2fs` is missing, install `e2fsprogs` on Debian/Ubuntu or `e2fsprogs-extra` on Alpine.

If `/` is ext4, replace the placeholder with **that exact partition**:

```sh
resize2fs /dev/ROOT_PARTITION
df -h /
```

This grows ext4 into available space on its existing partition. Do not run it against a different partition.

## Rootfs details

| Build | Artifact | Image | Ext4 label |
| --- | --- | --- | --- |
| Integrated / Debian | `channel-mainline-debian` | `rootfs.ext4.zst` | `rootfs` |
| Debian, Ubuntu, Alpine rootfs | `rootfs` | `rootfs.ext4.zst` | `rootfs` |

- Format: ext4 (raw, zstd-compressed)
- Ext4 UUID: `89530000-6320-4000-8000-000000000001`
