# ssh.service drop-ins

## `10-channel-usb.conf`

This drop-in makes `ssh.service` require and start after `channel-usb-gadget.service`.

Its purpose in this project is to keep sshd startup ordered behind creation of the USB network interface used by the generated rootfs.
