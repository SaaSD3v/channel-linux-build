# SSH configuration overlay

The Alpine rootfs runs the project-owned `channel-sshd` OpenRC service rather than the stock service. It starts only after the USB RNDIS gadget is ready.

`sshd_config.d/10-channel-usb.conf` binds sshd to `172.16.42.1`. `scripts/build-rootfs.sh` rewrites its authentication directives for the selected build mode.
