# GitHub Actions workflows

## `build.yml`

Integrated `alpine` branch build: kernel, modules, lk2nd, DTBO, Alpine rootfs, rootfs-independent boot image and final artifacts.

## `rootfs.yml`

Manual Alpine rootfs build for the selected ref. It builds a matching kernel internally so the rootfs receives the correct modules; no initramfs is generated.

The kernel, DTBO and lk2nd component workflows are unchanged because those components are distribution-independent.
