# Fixed SSH configuration

`10-channel-usb.conf` binds the project SSH service to the Channel USB
management address. Root access uses the single fixed `ssh` mode; the rootfs
builder no longer selects key/password authentication methods.
