# Channel runtime helpers

- `channel-usb-gadget` creates the configfs RNDIS gadget and assigns `172.16.42.1/24`.
- `channel-wifi-firmware` exposes the stock modem/vendor WCNSS firmware, starts the WCNSS remote processor, and loads the WCN36xx path.

Wi-Fi association, DHCP, routes, DNS, and persistent connection profiles are handled by Alpine's packaged NetworkManager. The removed Channel-specific supplicant/DHCP/config-watcher helpers are not part of this runtime.

NetworkManager explicitly leaves `usb0` unmanaged; the Channel USB gadget plus dnsmasq own that interface.
