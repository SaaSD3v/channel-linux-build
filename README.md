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

## Rootfs details

| Build | Artifact | Image | Ext4 label |
| --- | --- | --- | --- |
| Integrated / Debian | `channel-mainline-debian` | `rootfs.ext4.zst` | `rootfs` |
| Debian, Ubuntu, Alpine rootfs | `rootfs` | `rootfs.ext4.zst` | `rootfs` |

- Format: ext4 (raw, zstd-compressed)
- Ext4 UUID: `89530000-6320-4000-8000-000000000001`
