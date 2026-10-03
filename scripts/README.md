# Build scripts

## `build-kernel.sh`

Builds the existing Channel mainline kernel, DTB and modules and validates the WCN36xx/WCNSS configuration.

## `build-rootfs.sh`

Bootstraps Alpine 3.24.2 aarch64 from the official minirootfs, verifies its SHA-256, installs the required `apk` packages, applies `rootfs/`, configures OpenRC/SSH/Wi-Fi, installs the matching kernel modules, builds an Alpine `mkinitfs` initramfs, and creates `alpine-channel-rootfs.ext4.zst`.

## `build-bootimg.sh`

Packs `boot-channel.img` from the kernel + Channel DTB + Alpine initramfs. The default command line mounts `root=LABEL=alpine-rootfs`.
