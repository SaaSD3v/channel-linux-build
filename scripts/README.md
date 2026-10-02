# Build scripts

This directory contains the project build helpers used by the workflows.

## `build-kernel.sh`

Configures and builds the Channel kernel from an already-cloned kernel tree. It merges `config/channel-mainline.config`, verifies required built-in options, builds the kernel/DTBs/modules, and writes the kernel release and selected build outputs to `OUT_DIR`.

The separated kernel and rootfs workflows use this helper. The integrated `main` workflow keeps its in-workflow kernel build logic, but applies and validates the same `wcn3620-fix.patch` used by this helper.

## `build-rootfs.sh`

Creates the Debian Trixie ARM64 rootfs, copies the `rootfs/` overlay, installs the kernel modules, validates the target sshd configuration, generates the initramfs, and produces the compressed ext4 image.

The main and `rootfs` branches use the same selectable SSH authentication implementation. Manual workflows can select key, password, combined, or disabled modes; automatic builds preserve the public-key-first behavior.

## `build-bootimg.sh`

Helper for packing `boot-channel.img` from a built kernel, Channel DTB, and matching initramfs.

The known integrated `main` workflow currently packs its boot image inline with a pinned AOSP `mkbootimg`; this helper is retained as a repository build helper and is not substituted for that proven integrated step.
