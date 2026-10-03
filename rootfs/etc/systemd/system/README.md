# Channel systemd units

This directory contains the project systemd units copied into the generated rootfs.

## `channel-usb-gadget.service`

Runs the Channel USB gadget setup helper and keeps the gadget configured for the rest of the boot.

## `channel-dhcp.service`

Starts dnsmasq for the `usb0` link after the USB gadget service is available.

## `ssh.service.d/`

Contains the sshd ordering drop-in so sshd starts after the Channel USB gadget service.

These files are build inputs; the generated rootfs contains the enabled units.

## Channel Wi-Fi

`channel-wifi-firmware.service` mounts the stock Channel modem/vendor partitions
read-only, exposes the validated WCNSS firmware/NV files under `/lib/firmware`,
then starts the WCNSS remote processor and `wcn36xx`.

When CI Wi-Fi credentials are supplied, `channel-wifi-supplicant.service`
associates `wlan0` and `channel-wifi-dhcp-client.service` obtains and renews
IPv4 configuration with the validated BusyBox udhcpc hook.

`systemd-timesyncd` is enabled so the broken hardware RTC is corrected after
network connectivity becomes available.
