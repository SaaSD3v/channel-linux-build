# Rootfs `/etc` overlay

This directory contains device-specific configuration installed into the generated Ubuntu rootfs.

- `ssh/` contains the USB-only Channel SSH policy.
- `systemd/` contains the USB, DHCP and Wi-Fi service ordering.
- `modprobe.d/` contains WCNSS module ordering.

All other files come from Ubuntu Base and Ubuntu packages during the rootfs build.
