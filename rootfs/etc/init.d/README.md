# OpenRC services

These services preserve the Debian branch service split while using Alpine/OpenRC.

- `channel-usb-gadget` prepares the RNDIS gadget and assigns `172.16.42.1/24`.
- Alpine's packaged `dnsmasq` OpenRC service serves DHCP on `usb0` from `/etc/dnsmasq-channel-usb.conf`.
- `channel-sshd` starts OpenSSH only after the USB gadget is ready.
- `channel-wifi-firmware` prepares the stock modem/vendor WCNSS firmware and loads the WCN36xx path.
- `channel-wifi-supplicant` runs `wpa_supplicant` for `wlan0`.
- `channel-wifi-dhcp-client` waits for association and runs the Wi-Fi DHCP helper.
- `channel-wifi-config` is the OpenRC equivalent of Debian's `channel-wifi-config.path`: when the configuration file appears, it starts the DHCP client dependency chain.

Like the Debian branch, the Wi-Fi dependency chain is firmware -> supplicant -> DHCP. The firmware service and config watcher are enabled at boot by `scripts/build-rootfs.sh`. USB DHCP uses Alpine's stock `dnsmasq` service rather than a project-owned OpenRC wrapper.
