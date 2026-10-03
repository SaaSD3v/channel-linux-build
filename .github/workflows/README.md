# GitHub Actions workflows

## `build.yml`

Integrated `ubuntu` branch build: Channel mainline kernel/modules, lk2nd, DTBO, Ubuntu Minimal rootfs and the rootfs-independent `boot-channel.img`.

## `rootfs.yml`

Manual Ubuntu Minimal rootfs build using a freshly built matching Channel kernel for the module tree; no initramfs is generated.

The other component workflow files retain the existing kernel/DTBO/lk2nd build paths inherited from `main`.
