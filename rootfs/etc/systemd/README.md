# systemd rootfs overlay

This directory contains systemd configuration installed into the generated Debian rootfs.

The project units live under `system/` and coordinate:

- creation of the Channel USB gadget;
- DHCP service on the generated USB network;
- ordering of sshd after the USB gadget is ready.

The workflow enables the required units while assembling the rootfs.
