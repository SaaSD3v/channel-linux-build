# USB SSH overlay

The active drop-in in `sshd_config.d/` defines the fixed USB SSH management
mode (`ssh`) for root on `172.16.42.1`. No build-time selection or generated
user credential artifact is supported. Runtime network isolation must be
verified on the connected device.
