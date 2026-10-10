# Build scripts

This directory contains the project build helpers used by the workflows.

## `build-kernel.sh`

Configures and builds the Channel kernel from an already-cloned kernel tree. It merges `config/channel-mainline.config`, verifies required built-in options, builds the kernel/DTBs/modules, and writes the kernel release and selected build outputs to `OUT_DIR`.

The integrated, separated kernel, and rootfs workflows use this helper for kernel configuration and compilation. The Channel WCN3620 device-tree fix is already present in `SaaSD3v/linux:msm8953/latest`, so no local patch is applied. The helper still verifies the required built-in/module states, including the Channel WCNSS path.

## `build-rootfs.sh`

Creates the Debian Trixie ARM64 rootfs, copies the `rootfs/` overlay, installs the matching kernel modules, validates the target sshd configuration, and produces the compressed ext4 image without an initramfs.

The integrated build and the separated Debian rootfs workflow use the same fixed USB SSH mode, named `ssh`. There are no SSH authentication inputs or generated user credential artifacts.

## `build-bootimg.sh`

Helper for packing the rootfs-independent `boot-channel.img` from a built kernel and Channel DTB. It uses the fixed Channel root-partition PARTUUID and no initramfs.

The integrated `main` workflow uses this helper as the single boot-image packer and supplies the pinned AOSP `mkbootimg.py`. The helper also writes `kernel-cmdline.txt` so the exact boot command line is published with the artifacts.
