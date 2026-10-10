# Channel Linux Build

Mainline Linux for the Motorola Moto G7 Play (`channel`).

## Workflows

The `main` branch hosts the integrated build and component launchers.

The `debian`, `ubuntu` and `alpine` branches each provide a standalone `rootfs.yml`. The `kernel-mainline-7.1`, `dtbo` and `lk2nd` branches build the corresponding boot components.

Run the desired workflow from **Actions**. A rootfs workflow can reuse a compatible kernel build.

## Output

The integrated workflow publishes the Debian rootfs, kernel boot image, DTBO and lk2nd. Standalone rootfs builds publish `rootfs.ext4.zst`; the kernel workflow publishes `boot-channel.img` and matching modules.

Kernel source: [SaaSD3v/linux](https://github.com/SaaSD3v/linux), `msm8953/latest`.

## Rootfs image

The workflow produces `rootfs.ext4.zst`, a compressed raw ext4 filesystem. Extract it on the host:

```sh
zstd -d -k rootfs.ext4.zst
```

Use your existing lk2nd boot setup to deploy the rootfs.

After boot, check the root filesystem using `findmnt -n -o SOURCE,FSTYPE /` and `df -h /`. Only if the verified root partition is ext4 and has unused space, use `resize2fs` with the confirmed device path.

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
