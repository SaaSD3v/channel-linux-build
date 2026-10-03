# Channel runtime helpers

- `channel-usb-gadget` creates the configfs RNDIS gadget and assigns `172.16.42.1/24`.
- `channel-wifi` is the OpenRC-supervised Wi-Fi manager. It waits for runtime configuration and coordinates firmware, supplicant and DHCP.
- `channel-wifi-firmware` exposes stock modem/vendor WCNSS firmware and loads the WCN36xx path.
- `channel-wifi-dhcp` waits for association and runs BusyBox `udhcpc`.
