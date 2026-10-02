# Channel systemd units

This directory contains the project systemd units copied into the generated rootfs.

## `channel-usb-gadget.service`

Runs the Channel USB gadget setup helper and keeps the gadget configured for the rest of the boot.

## `channel-dhcp.service`

Starts dnsmasq for the `usb0` link after the USB gadget service is available.

## `ssh.service.d/`

Contains the sshd ordering drop-in so sshd starts after the Channel USB gadget service.

These files are build inputs; the generated rootfs contains the enabled units.
