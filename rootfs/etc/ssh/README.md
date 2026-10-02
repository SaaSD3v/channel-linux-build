# SSH configuration overlay

This directory contains SSH configuration shipped with the generated rootfs.

The active drop-in is under `sshd_config.d/`.

The separated `rootfs` workflow can render the final authentication settings during the build according to the selected `ssh_auth` mode. The repository file provides the project baseline; the generated image contains the effective settings for that run.
