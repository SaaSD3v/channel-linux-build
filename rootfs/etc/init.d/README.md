# OpenRC services

These services provide the Channel hardware-specific boot pieces while using
standard Alpine network management.

- `channel-usb-gadget` prepares the RNDIS gadget and assigns `172.16.42.1/24`.
- Alpine's packaged `dnsmasq` OpenRC service serves DHCP on `usb0` from `/etc/dnsmasq-channel-usb.conf`.
- `channel-sshd` starts OpenSSH only after the USB gadget is ready.
- `channel-wifi-firmware` prepares the stock modem/vendor WCNSS firmware and loads the WCN36xx path.
- Alpine's packaged `networkmanager` service owns `wlan0`, Wi-Fi association, DHCP, routes and DNS.

The firmware service is ordered before NetworkManager. Wi-Fi can be configured
at runtime with `nmcli dev wifi list` and
`nmcli dev wifi connect <SSID> password <PASSWORD>`.

USB RNDIS remains independent from Wi-Fi and continues to use the existing
Channel gadget plus dnsmasq setup.
