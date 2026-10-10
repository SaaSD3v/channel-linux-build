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

## Rootfs build

Use `.github/workflows/rootfs.yml` to build the Ubuntu userspace with matching
kernel modules. It reuses the kernel checkpoint when possible and otherwise
builds the matching kernel as an internal dependency. This generates a rootfs
image, not a new boot image or initramfs.

The obsolete integrated `build.yml` (which expected a missing initramfs
builder) was removed from this branch. The validated standalone kernel build
publishes the direct-root `boot-channel.img` using
`root=PARTUUID=76dbdefa-f243-cd22-5da5-9374e6ad318b`.

SSH management uses one fixed mode, `ssh`, without workflow authentication
inputs or downloadable user credentials. For a host connected over USB, the
intended connection is `ssh root@172.16.42.1`. Test SSH and network isolation
on the device before relying on it.
