# Rootfs overlay

This directory is copied into the generated Ubuntu Minimal root filesystem.

It contains project-owned device configuration only:

- SSH policy under `etc/ssh/`;
- systemd units and ordering under `etc/systemd/`;
- Channel USB/Wi-Fi runtime helpers under `usr/local/`.

The Ubuntu Base filesystem and distro packages are fetched during `scripts/build-rootfs.sh`; no distro rootfs binary is stored in this repository.
