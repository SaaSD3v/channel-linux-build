# Kernel-only build helpers

`build-kernel.sh` configures, builds and validates the Channel mainline kernel,
DTB and matching modules. `build-bootimg.sh` packages the direct-root
`boot-channel.img` without an initramfs.

This component branch builds no rootfs or SSH configuration. Userspace builders
are maintained in the rootfs-specific branches.
