# Build scripts

## `build-kernel.sh`

Builds the existing Channel mainline kernel, DTB and modules and validates the WCN36xx/WCNSS configuration.

## `build-rootfs.sh`

Bootstraps Alpine 3.24.2 aarch64 from the official minirootfs, verifies its SHA-256, installs the required `apk` packages, applies `rootfs/`, configures OpenRC/SSH/Wi-Fi, installs the matching kernel modules, and creates `alpine-channel-rootfs.ext4.zst` without generating an initramfs.

## `build-bootimg.sh`

Packs the shared `boot-channel.img` from the kernel + Channel DTB with no initramfs. The default command line mounts `root=PARTUUID=76dbdefa-f243-cd22-5da5-9374e6ad318b`.
