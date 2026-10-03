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

NetworkManager owns `wlan0`, association, DHCP, routes and DNS. The firmware
service is ordered before NetworkManager so the validated WCNSS path is ready
before normal Wi-Fi management begins.

`usb0` is explicitly unmanaged by NetworkManager. The Channel USB gadget and
`channel-dhcp.service` retain exclusive ownership of the RNDIS management link.

Use `nmcli dev wifi list` and `nmcli dev wifi connect <SSID> password <PASSWORD>`
to configure Wi-Fi at runtime.

`systemd-timesyncd` is enabled so the broken hardware RTC is corrected after
network connectivity becomes available.
