# sshd drop-ins

`10-channel-usb.conf` is the baseline Alpine/OpenSSH policy. It restricts sshd to the Channel USB management address. The rootfs builder rewrites authentication settings for the selected key/password/open-root mode and validates the final target configuration with `sshd -t`.
