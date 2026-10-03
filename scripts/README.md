# Build scripts

This directory contains the project build helpers used by the workflows.

## `build-kernel.sh`

Configures and builds the Channel kernel from an already-cloned kernel tree. It merges `config/channel-mainline.config`, verifies required built-in options, builds the kernel/DTBs/modules, and writes the kernel release and selected build outputs to `OUT_DIR`.

The main, separated kernel, and rootfs workflows use this helper for kernel configuration and compilation. It applies the validated `wcn3620-fix.patch` and verifies the Channel WCNSS configuration.

## `build-rootfs.sh`

Creates the Debian Trixie ARM64 rootfs, copies the `rootfs/` overlay, installs the matching kernel modules, validates the target sshd configuration, and produces the compressed ext4 image without an initramfs.

The separated `debian` branch includes the selectable SSH authentication modes documented in its top-level README, including `open-root-usb` for local bring-up.

## `build-bootimg.sh`

Helper for packing the rootfs-independent `boot-channel.img` from a built kernel and Channel DTB, without an initramfs.

The known integrated `main` workflow currently packs its boot image inline with a pinned AOSP `mkbootimg`; this helper is retained as a repository build helper and is not substituted for that proven integrated step.
