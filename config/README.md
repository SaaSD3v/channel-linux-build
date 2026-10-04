# Kernel configuration

This directory contains project-owned kernel configuration fragments.

## `channel-mainline.config`

This fragment is merged on top of the kernel's ARM64 `defconfig` during Channel builds.

It keeps the options required by the current build flow, including:

- initrd support retained for kernel compatibility; generated Channel boot images themselves contain no initramfs;
- ext4 and MMC/SDHCI storage support;
- Qualcomm DWC3 USB gadget support;
- configfs and RNDIS support;
- basic networking used by the generated rootfs;
- a small set of bring-up/debug options.

The final kernel configuration is produced by the build workflow or `scripts/build-kernel.sh`; this file is only the project-specific fragment.
