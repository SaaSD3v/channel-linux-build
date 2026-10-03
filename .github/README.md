# GitHub automation

On the `ubuntu` branch, the integrated workflow builds the Channel kernel/lk2nd/DTBO plus the Ubuntu Minimal rootfs. The rootfs workflow is available for a rootfs-focused manual build.

Device runtime fixes live in the rootfs overlay and distro configuration; the workflows only assemble and validate them.
