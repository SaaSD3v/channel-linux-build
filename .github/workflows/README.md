# Debian rootfs GitHub Actions

`rootfs.yml` builds the Debian rootfs with matching kernel modules, normally
reusing a validated kernel artifact. It has manual dispatch and push triggers.
SSH authentication is not selectable: USB SSH is fixed and no user credential
artifacts are published. Kernel and boot-only workflows are separate.
