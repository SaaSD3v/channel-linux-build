# sshd configuration drop-ins

## `10-channel-usb.conf`

This file is the Channel-specific sshd drop-in.

The baseline configuration binds sshd to the Channel USB network address and defines the default authentication policy used by the existing integrated build.

In the separated `rootfs` workflow, `scripts/build-rootfs.sh` may rewrite this drop-in inside the generated rootfs to match the selected manual authentication mode. The repository copy remains the baseline input.
