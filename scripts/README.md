# LK2ND component branch

This component branch builds only the Channel lk2nd bootloader using
`.github/workflows/lk2nd.yml`. Legacy rootfs, SSH authentication, and
obsolete initramfs-dependent boot helper copies have been removed.

Kernel and rootfs components are built by their dedicated workflows.
