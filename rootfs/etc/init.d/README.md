# OpenRC services

These services replace the former systemd units for the Alpine rootfs.

- `channel-usb-gadget` prepares the RNDIS gadget and assigns `172.16.42.1/24`.
- `channel-dhcp` serves DHCP on `usb0`.
- `channel-sshd` starts OpenSSH only after the USB gadget is ready.
- `channel-wifi` supervises the Channel WCNSS firmware, `wpa_supplicant`, and DHCP flow.

All four services are enabled by `scripts/build-rootfs.sh`.
