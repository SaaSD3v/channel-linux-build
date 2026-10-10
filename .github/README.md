# GitHub automation

The `ubuntu` branch keeps its Ubuntu rootfs workflow; obsolete integrated and duplicate kernel workflows were retired. For boot/kernel/DTBO/lk2nd use the canonical standalone workflows. SSH authentication is fixed for the USB rootfs.

Device runtime fixes live in the rootfs overlay and distro configuration; the workflows only assemble and validate them.
