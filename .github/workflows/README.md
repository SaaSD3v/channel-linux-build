# Kernel workflow

This directory contains `kernel-mainline-7.1.yml`, the separated kernel build for this branch.

It clones the Channel kernel source, runs the project kernel helper, packages the matching modules, builds the rootfs-independent `boot-channel.img`, and uploads only kernel-side artifacts. It does not build a distro rootfs or handle SSH credentials.

Pushes to `kernel-mainline-7.1` run this workflow automatically. The copy exposed on `main` is used for manual dispatch.
