# Ubuntu rootfs workflow

`rootfs.yml` builds the Ubuntu ARM64 rootfs using matching kernel modules.
The obsolete integrated and duplicated kernel workflows were removed from
this branch; use the validated separate mainline kernel build for boot images.
SSH access uses a single fixed USB mode, without authentication choices.
