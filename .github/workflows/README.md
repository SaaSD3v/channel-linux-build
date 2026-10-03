# Rootfs workflow

This directory contains `rootfs.yml`, the separated Debian rootfs workflow for the `debian` branch.

It builds the kernel dependency required by the rootfs, runs `scripts/build-rootfs.sh`, publishes the rootfs artifacts without an initramfs, and handles the manual SSH authentication inputs documented in the branch's top-level README.

Pushes to `debian` run this workflow automatically. The copy exposed on `main` is used for manual dispatch.
