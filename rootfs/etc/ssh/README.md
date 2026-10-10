# Alpine USB SSH overlay

The project-owned `channel-sshd` OpenRC service starts after the USB gadget.
`sshd_config.d/10-channel-usb.conf` is the fixed SSH policy, listening on
`172.16.42.1`; there is no workflow-selectable authentication mode.
