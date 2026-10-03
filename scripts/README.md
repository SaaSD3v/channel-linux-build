# Build scripts

## `build-kernel.sh`

Builds and validates the existing Channel mainline kernel, DTB and modules.

## `build-rootfs.sh`

Downloads the official Ubuntu Base 26.04.1 LTS ARM64 rootfs, verifies its pinned SHA-256, installs the minimal runtime package set, applies `rootfs/`, installs the matching Channel kernel modules, creates the matching `initramfs-tools` initramfs, and writes `ubuntu-channel-rootfs.ext4.zst`.

## `build-bootimg.sh`

Packs `boot-channel.img` from the Channel kernel + DTB + Ubuntu initramfs. The default command line mounts `root=LABEL=ubuntu-rootfs`.
