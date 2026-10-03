# Build scripts

## `build-kernel.sh`

Builds and validates the existing Channel mainline kernel, DTB and modules.

## `build-rootfs.sh`

Downloads the official Ubuntu Base 26.04.1 LTS ARM64 rootfs, verifies its pinned SHA-256, installs the minimal runtime package set, applies `rootfs/`, installs the matching Channel kernel modules, and writes `ubuntu-channel-rootfs.ext4.zst` without generating an initramfs.

## `build-bootimg.sh`

Packs the shared `boot-channel.img` from the Channel kernel + DTB with no initramfs. The default command line mounts `root=PARTUUID=76dbdefa-f243-cd22-5da5-9374e6ad318b`.
