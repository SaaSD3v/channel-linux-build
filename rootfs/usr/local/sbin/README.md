# Channel runtime helpers

- `channel-usb-gadget` creates the configfs RNDIS gadget and assigns `172.16.42.1/24`.
- `channel-wifi-firmware` exposes stock modem/vendor WCNSS firmware and loads the WCN36xx path.
- `channel-wifi-dhcp` waits for association and runs BusyBox `udhcpc`.
- `channel-wifi-config` watches for the runtime wpa_supplicant configuration and starts the same firmware -> supplicant -> DHCP service chain used by the Debian branch.
