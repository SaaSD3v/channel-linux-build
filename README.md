# Moto G7 Play (channel) — Ubuntu Minimal mainline

This branch builds an Ubuntu Minimal userspace for the Motorola Moto G7 Play (`channel`, Qualcomm SDM632) while preserving the validated mainline kernel/lk2nd/DTBO flow from `main`.

## Userspace

The rootfs is based on the official **Ubuntu Base 26.04.1 LTS (Resolute) ARM64** tarball. The build verifies the pinned upstream SHA-256 before extracting it, then installs only the packages required for the headless device:

- systemd/udev/dbus;
- OpenSSH;
- iproute2 and ping;
- dnsmasq;
- initramfs-tools + BusyBox;
- WCN36xx userspace tools (`iw`, `wpasupplicant`, `wireless-regdb`);
- systemd-timesyncd;
- small administration utilities.

No Ubuntu kernel or bootloader package is used. The rootfs receives the Channel mainline kernel modules produced by this repository.

The generated filesystem is:

`ubuntu-channel-rootfs.ext4.zst`

with filesystem label:

`ubuntu-rootfs`

## USB SSH

The USB behavior intentionally matches the Debian branch:

- RNDIS gadget on `usb0`;
- device address `172.16.42.1/24`;
- dnsmasq gives the Windows/Linux host `172.16.42.2` through `172.16.42.20`;
- sshd listens only on `172.16.42.1`.

The expected host behavior is automatic DHCP; a manual Windows IPv4 address should not be required.

## Wi-Fi

The Debian service split is kept unchanged:

`channel-wifi-firmware.service` -> `channel-wifi-supplicant.service` -> `channel-wifi-dhcp-client.service`

and `channel-wifi-config.path` watches:

`/etc/wpa_supplicant/wpa_supplicant-channel.conf`

Runtime setup is the same:

```sh
wpa_passphrase "<network-name>" "<password>" > /etc/wpa_supplicant/wpa_supplicant-channel.conf
chmod 600 /etc/wpa_supplicant/wpa_supplicant-channel.conf
```

The path unit starts the dependency chain when the file exists. Stock modem/vendor WCNSS firmware is mounted read-only just like on Debian.

## Build

The integrated workflow builds the kernel, modules, lk2nd, Channel DTBO, Ubuntu rootfs/initramfs and `boot-channel.img`.

The default boot cmdline uses:

`root=LABEL=ubuntu-rootfs rootfstype=ext4 rootwait rw`

SSH authentication modes from the Debian branch are preserved, including `open-root-usb` for bring-up.
