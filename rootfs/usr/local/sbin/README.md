# Channel runtime helpers

## `channel-usb-gadget`

This script creates the Channel configfs USB gadget used by the generated rootfs.

During execution it:

- waits for the Qualcomm UDC;
- removes a previous Channel gadget instance when present;
- creates the RNDIS function and Microsoft OS descriptors;
- binds the gadget to the detected UDC;
- waits for `usb0`;
- assigns `172.16.42.1/24` to the device side of the link.

The script is started by `channel-usb-gadget.service`.
