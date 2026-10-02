# Build scripts

This directory contains the project build helpers used by the workflows.

## `build-kernel.sh`

Configures and builds the Channel kernel from an already-cloned kernel tree. It merges `config/channel-mainline.config`, verifies required built-in options, builds the kernel/DTBs/modules, and writes the kernel release and selected build outputs to `OUT_DIR`.

The main, separated kernel, and rootfs workflows use this helper for kernel configuration and compilation. It applies the validated `wcn3620-fix.patch` and verifies the Channel WCNSS configuration.

## `build-rootfs.sh`

Creates the Debian Trixie ARM64 rootfs, copies the `rootfs/` overlay, installs the kernel modules, validates the target sshd configuration, generates the initramfs, and produces the compressed ext4 image.

The exact SSH authentication behavior depends on the version of this script in the branch. The separated `rootfs` branch includes the selectable authentication modes documented in its top-level README.

## `build-bootimg.sh`

Helper for packing `boot-channel.img` from a built kernel, Channel DTB, and matching initramfs.

The known integrated `main` workflow currently packs its boot image inline with a pinned AOSP `mkbootimg`; this helper is retained as a repository build helper and is not substituted for that proven integrated step.
