# Build scripts

This directory contains the project build helpers used by the workflows.

## `build-kernel.sh`

Configures and builds the Channel kernel from an already-cloned kernel tree. It merges `config/channel-mainline.config`, verifies required built-in options, builds the kernel/DTBs/modules, and writes the kernel release and selected build outputs to `OUT_DIR`.

The integrated, separated kernel, and rootfs workflows use this helper for kernel configuration and compilation. It applies the validated `wcn3620-fix.patch` and verifies required built-in/module states, including the Channel WCNSS path.

## `build-rootfs.sh`

Creates the Debian Trixie ARM64 rootfs, copies the `rootfs/` overlay, installs the matching kernel modules, validates the target sshd configuration, and produces the compressed ext4 image without an initramfs.

The main integrated build and the `debian` rootfs branch use the same selectable SSH authentication implementation. Manual rootfs workflows support key, password, combined, or `open-root-usb` modes; automatic builds preserve the public-key-first behavior.

## `build-bootimg.sh`

Helper for packing the rootfs-independent `boot-channel.img` from a built kernel and Channel DTB. It uses the fixed Channel root-partition PARTUUID and no initramfs.

The integrated `main` workflow uses this helper as the single boot-image packer and supplies the pinned AOSP `mkbootimg.py`. The helper also writes `kernel-cmdline.txt` so the exact boot command line is published with the artifacts.
