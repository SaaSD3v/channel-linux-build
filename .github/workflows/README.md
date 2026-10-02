# GitHub Actions workflows

This branch exposes the integrated build and the manual launchers for all separated component builds.

## `build.yml`

Runs the complete Channel build on `main`: kernel, modules, lk2nd, DTBO, Debian rootfs, initramfs, boot image, validation, and final artifacts.

## `rootfs.yml`

Manual launcher for the separated rootfs build. It checks out the `rootfs` branch before executing the rootfs workflow.

## `kernel-mainline-7.1.yml`

Manual launcher for the separated kernel build. It checks out `kernel-mainline-7.1`.

## `dtbo.yml`

Manual launcher for the separated DTBO build. It checks out `dtbo`.

## `lk2nd.yml`

Manual launcher for the separated lk2nd build. It checks out `lk2nd`.

Keeping these files on the default branch makes their **Run workflow** controls available in GitHub Actions.
