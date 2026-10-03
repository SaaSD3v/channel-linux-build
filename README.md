# Moto G7 Play (channel) — Alpine mainline bring-up

This branch builds a headless Alpine Linux userspace for the Motorola Moto G7 Play (`channel`, Qualcomm SDM632) on the existing mainline kernel/lk2nd boot flow.

## What changed from `main`

The kernel, Channel DTB, WCN36xx fix, lk2nd, DTBO and Android boot-image layout stay the same. The userspace is Alpine Linux instead of Debian:

- Alpine 3.24.2 aarch64 minirootfs;
- OpenRC instead of systemd;
- `chronyd` instead of `systemd-timesyncd`;
- Alpine `apk` packages for OpenSSH, `wpa_supplicant`, dnsmasq, networking and utilities;
- root filesystem label `alpine-rootfs`;
- rootfs artifact `alpine-channel-rootfs.ext4.zst`.

The rootfs bootstrap verifies the official Alpine minirootfs SHA-256 before extracting it.

## Full build

`.github/workflows/build.yml` builds:

1. the Channel mainline kernel and modules;
2. lk2nd for MSM8953/SDM632;
3. the minimal Channel DTBO;
4. the Alpine rootfs with the matching kernel modules;
5. `boot-channel.img`.

The final rootfs artifact is `alpine-channel-rootfs.ext4.zst`. The shared boot image contains no initramfs and mounts the Channel root partition with `root=PARTUUID=76dbdefa-f243-cd22-5da5-9374e6ad318b rootfstype=ext4 rootwait rw`; the `alpine-rootfs` label is kept only for filesystem identification.

## USB SSH

The USB gadget remains RNDIS with:

- device: `172.16.42.1/24`;
- DHCP range: `172.16.42.2` through `172.16.42.20`;
- sshd listening only on `172.16.42.1`.

OpenRC starts `channel-usb-gadget` first, then Alpine's packaged `dnsmasq` service and `channel-sshd`. The Windows host receives `172.16.42.2`–`172.16.42.20` by DHCP without manual IPv4 configuration.

Manual builds support the existing authentication modes:

- `generated-key`;
- `public-key-input`;
- `public-key-secret`;
- `generated-password`;
- `password-secret`;
- `generated-key+generated-password`;
- `public-key-input+password-secret`;
- `public-key-secret+password-secret`;
- `open-root-usb`.

`open-root-usb` enables Alpine/OpenSSH empty-password authentication only on the USB-bound sshd. The Alpine image does not enable a local getty.

## Wi-Fi

The Channel WCNSS flow is preserved. `channel-wifi-firmware` mounts the stock modem/vendor partitions read-only, exposes the WCNSS firmware/NV files, starts `qcom_wcnss_pil`, then loads `wcn36xx`.

The Alpine branch keeps the same service split used by Debian:

`channel-wifi-firmware` -> `channel-wifi-supplicant` -> `channel-wifi-dhcp-client`

`channel-wifi-config` is the OpenRC equivalent of Debian's `channel-wifi-config.path`. It watches for:

`/etc/wpa_supplicant/wpa_supplicant-channel.conf`

When the file appears, the watcher starts the DHCP-client service; OpenRC dependencies then start the supplicant and firmware services in the same order as the Debian systemd units.

To configure Wi-Fi at runtime:

```sh
wpa_passphrase "<network-name>" "<password>" > /etc/wpa_supplicant/wpa_supplicant-channel.conf
chmod 600 /etc/wpa_supplicant/wpa_supplicant-channel.conf
```

The service notices the file without requiring a reboot. CI can also embed credentials with the existing `WIFI_SSID`, `WIFI_PASSWORD`, and optional `WIFI_COUNTRY` secrets.

After DHCP succeeds, the hook restarts `chronyd` so devices whose RTC starts near the Unix epoch immediately retry network time synchronization.

## Rootfs overlay

Project-owned Alpine runtime files live in `rootfs/`:

- `etc/init.d/` — device-specific OpenRC services; USB DHCP itself uses Alpine's packaged `dnsmasq` service;
- `etc/ssh/` — USB-only sshd policy;
- `etc/chrony/` — NTP configuration;
- `etc/modprobe.d/` — WCNSS autoload ordering;
- `usr/local/sbin/` — USB and Wi-Fi runtime helpers;
- `usr/local/libexec/` — the `udhcpc` lease hook.

## Storage

The rootfs is a standalone ext4 image labeled `alpine-rootfs`. This repository still does not repartition or flash the phone automatically; placement of the ext4 image remains a separate device-side step.
