# Moto G7 Play (channel) — Alpine mainline bring-up

## Canonical rootfs identity

All current Channel rootfs builds use one identity only:

- file: `rootfs.ext4.zst`
- ext4 label: `rootfs`
- ext4 UUID: `89530000-6320-4000-8000-000000000001`

The mainline boot image contains a small ARM64 initramfs that searches only for
that filesystem UUID, mounts it as the real root, and executes `/sbin/init`.
No root PARTUUID, distro-specific root label, or automatic fallback is used.


This branch builds a headless Alpine Linux userspace for the Motorola Moto G7 Play (`channel`, Qualcomm SDM632) on the existing mainline kernel/lk2nd boot flow.

## What changed from `main`

The kernel, Channel DTB, WCN36xx fix, lk2nd, DTBO and Android boot-image layout stay the same. The userspace is Alpine Linux instead of Debian:

- Alpine 3.24.2 aarch64 minirootfs;
- OpenRC instead of systemd;
- `chronyd` instead of `systemd-timesyncd`;
- Alpine `apk` packages for OpenSSH, `wpa_supplicant`, dnsmasq, networking and utilities;
- root filesystem label `rootfs`;
- rootfs artifact `rootfs.ext4.zst`.

The rootfs bootstrap verifies the official Alpine minirootfs SHA-256 before extracting it.

## Full build

`.github/workflows/build.yml` builds:

1. the Channel mainline kernel and modules;
2. lk2nd for MSM8953/SDM632;
3. the minimal Channel DTBO;
4. the Alpine rootfs with the matching kernel modules;
5. `boot-channel.img`.

The final rootfs artifact is `rootfs.ext4.zst`. The shared boot image contains a small fixed-UUID initramfs and mounts the Channel root partition with `initramfs lookup of filesystem UUID 89530000-6320-4000-8000-000000000001`; the `rootfs` label is kept only for filesystem identification.

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

The Channel WCNSS flow is preserved. `channel-wifi-firmware` mounts the stock
modem/vendor partitions read-only, exposes the WCNSS firmware/NV files, starts
`qcom_wcnss_pil`, then loads `wcn36xx`.

Alpine's packaged NetworkManager service owns `wlan0`, Wi-Fi association,
DHCP, routes, and DNS. The firmware service is ordered before NetworkManager.

Configure Wi-Fi at runtime with:

```sh
nmcli dev wifi list
nmcli dev wifi connect "<network-name>" password "<password>"
```

NetworkManager persists the connection profile for later boots. The old
Channel-specific supplicant, DHCP-client, config-watcher, and udhcpc helpers
are not used.

## Rootfs overlay

Project-owned Alpine runtime files live in `rootfs/`:

- `etc/init.d/` — Channel hardware/USB OpenRC services; Wi-Fi management itself uses Alpine's packaged `networkmanager` service;
- `etc/ssh/` — USB-only sshd policy;
- `etc/chrony/` — NTP configuration;
- `etc/modprobe.d/` — WCNSS autoload ordering;
- `usr/local/sbin/` — the USB gadget and Channel WCNSS firmware helpers.

## Storage

The rootfs is a standalone ext4 image labeled `rootfs`. This repository still does not repartition or flash the phone automatically; placement of the ext4 image remains a separate device-side step.
