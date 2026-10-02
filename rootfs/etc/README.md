# Rootfs `/etc` overlay

This directory contains configuration files installed into `/etc` of the generated Debian rootfs.

Current project configuration is split between:

- `ssh/` for the Channel SSH configuration;
- `systemd/` for the services and ordering used by the generated image.

Only files maintained by this project are kept here; the rest of `/etc` comes from the Debian rootfs created during the build.
