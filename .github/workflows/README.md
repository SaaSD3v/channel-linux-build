# GitHub Actions workflows

## `build.yml`

Integrated `ubuntu` branch build: Channel mainline kernel/modules, lk2nd, DTBO, Ubuntu Minimal rootfs, matching initramfs and `boot-channel.img`.

## `rootfs.yml`

Manual Ubuntu Minimal rootfs + initramfs build using a freshly built matching Channel kernel.

The other component workflow files retain the existing kernel/DTBO/lk2nd build paths inherited from `main`.
