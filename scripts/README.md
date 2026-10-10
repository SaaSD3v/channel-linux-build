# DTBO component branch

This component branch builds only the Channel DTBO using
`.github/workflows/dtbo.yml`. Legacy rootfs, SSH authentication, and
obsolete initramfs-dependent boot helper copies have been removed.

Kernel and rootfs components are built by their dedicated workflows.
