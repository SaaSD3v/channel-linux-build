# Fixed Channel SSH configuration

`10-channel-usb.conf` is the fixed Alpine sshd drop-in, intended for SSH root
over USB RNDIS. The builder does not select or generate user SSH credentials.
Validate access and USB-only isolation on the actual device.
