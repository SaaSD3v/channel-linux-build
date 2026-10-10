# Channel — Mainline Kernel

Standalone kernel build for the Motorola Moto G7 Play.

## Build

Run **Build kernel mainline 7.1** in GitHub Actions.

Source: [SaaSD3v/linux](https://github.com/SaaSD3v/linux), `msm8953/latest`.

The workflow builds the ARM64 kernel, `sdm632-motorola-channel.dtb`, matching modules and a direct-root `boot-channel.img`.

## Artifacts

The `channel-kernel-mainline-7.1` artifact contains the boot image, kernel and DTB files, modules, build configuration and checksums.

The boot image has no initramfs. This branch does not build a rootfs, DTBO or lk2nd.

## Root partition convention

The boot image uses `root=PARTLABEL=userdata rootfstype=ext4 rootwait` and contains no initramfs. It targets the existing GPT partition named `userdata` on a phone configured for a Linux ext4 rootfs. The ext4 filesystem LABEL and UUID may vary; stock Android data must not be overwritten unintentionally.
