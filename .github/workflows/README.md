# Alpine rootfs workflow

`rootfs.yml` builds the Alpine userspace, installs matching kernel modules and
publishes rootfs artifacts. USB SSH is fixed, with no authentication controls.
The obsolete integrated `build.yml` and duplicated legacy kernel workflow have
been removed from this branch; use the separate validated kernel build.
