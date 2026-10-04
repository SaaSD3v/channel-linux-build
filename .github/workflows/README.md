# GitHub Actions workflows

This branch exposes the integrated build and the manual launchers for all separated component builds.

## `build.yml`

Runs the complete Channel build on `main`: kernel, modules, lk2nd, DTBO, Debian rootfs, rootfs-independent boot image, validation, and final artifacts.

## `rootfs.yml`

Manual launcher for the separated rootfs build. The distro workflow first reuses a live `channel-kernel-mainline-7.1` artifact when available; otherwise it builds the same GitHub kernel locally for that run and publishes only the rootfs outputs.

## `kernel-mainline-7.1.yml`

Manual launcher for the separated kernel build using `SaaSD3v/linux:msm8953/latest`. Its `boot-channel.img` has no initramfs and mounts `userdata` directly by PARTUUID.

## `kernel-github.yml`

Manual launcher for the direct GitHub-kernel build. It uses the same direct-root PARTUUID boot model and contains no BusyBox/initramfs stage.

## `dtbo.yml`

Manual launcher for the separated DTBO build. It checks out `dtbo`.

## `lk2nd.yml`

Manual launcher for the separated lk2nd build. It checks out `lk2nd`.

Keeping these files on the default branch makes their **Run workflow** controls available in GitHub Actions.
