# Moto G7 Play (channel) — Ubuntu Minimal mainline

This branch builds an Ubuntu Minimal userspace for the Motorola Moto G7 Play (`channel`, Qualcomm SDM632) while preserving the validated mainline kernel/lk2nd/DTBO flow from `main`.

## Userspace

The rootfs is based on the official **Ubuntu Base 26.04.1 LTS (Resolute) ARM64** tarball. The build verifies the pinned upstream SHA-256 before extracting it, then installs only the packages required for the headless device:

- systemd/udev/dbus;
- OpenSSH;
- iproute2 and ping;
- dnsmasq;
- BusyBox for the existing runtime DHCP helper;
- WCN36xx userspace tools (`iw`, `wpasupplicant`, `wireless-regdb`);
- systemd-timesyncd;
- small administration utilities.

No Ubuntu kernel or bootloader package is used. The rootfs receives the Channel mainline kernel modules produced by this repository.

The generated filesystem is:

`rootfs.ext4.zst`

with filesystem label:

`rootfs`

## USB SSH

The USB behavior intentionally matches the Debian branch:

- RNDIS gadget on `usb0`;
- device address `172.16.42.1/24`;
- dnsmasq gives the Windows/Linux host `172.16.42.2` through `172.16.42.20`;
- sshd listens only on `172.16.42.1`.

The expected host behavior is automatic DHCP; a manual Windows IPv4 address should not be required.

## Wi-Fi

`channel-wifi-firmware.service` keeps the validated Channel-specific WCNSS
firmware path: it mounts the stock modem/vendor partitions read-only, prepares
the firmware/NV files, starts the remote processor, and loads `wcn36xx`.

NetworkManager then owns `wlan0`, Wi-Fi association, DHCP, routes, and DNS.
The firmware service is ordered before NetworkManager.

Configure Wi-Fi with:

```sh
nmcli dev wifi list
nmcli dev wifi connect "<network-name>" password "<password>"
```

NetworkManager persists the connection profile for later boots. The old
Channel-specific supplicant, DHCP-client service, config watcher, and udhcpc
hook are not used.

## Build

The integrated workflow builds the kernel, modules, lk2nd, Channel DTBO, Ubuntu rootfs and the shared rootfs-independent `boot-channel.img`.

The default boot cmdline uses:

`root=PARTUUID=76dbdefa-f243-cd22-5da5-9374e6ad318b rootfstype=ext4 rootwait rw`

The boot image contains no initramfs; the `rootfs` label remains for filesystem identification only. SSH authentication modes from the Debian branch are preserved, including `open-root-usb` for bring-up.

## GitHub Actions launchers

Kernel reuse is **off by default**: a normal rootfs run compiles the current
`SaaSD3v/linux:msm8953/latest`. Select `reuse_kernel` to use a published
kernel artifact; `kernel_run_id` is only accepted when reuse is enabled.

For `open-root-usb`, choose the dedicated `Build Ubuntu rootfs (USB open root)` workflow exposed on the `main`
branch. It shows only a reuse checkbox, not SSH key/password fields.
The regular SSH workflow no longer lists `open-root-usb` as an option.
GitHub Actions cannot hide workflow_dispatch fields dynamically.
