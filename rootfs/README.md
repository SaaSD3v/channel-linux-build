# Rootfs overlay

This directory is copied into the generated Debian root filesystem.

It contains only project-owned files that must be present in the final rootfs:

- SSH configuration under `etc/ssh/`;
- systemd units and drop-ins under `etc/systemd/`;
- the Channel USB gadget helper under `usr/local/sbin/`.

The rootfs image itself is not stored here. It is created by `scripts/build-rootfs.sh` and published by GitHub Actions as an artifact.
