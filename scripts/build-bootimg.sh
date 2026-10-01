#!/usr/bin/env bash
set -euo pipefail

: "${KERNEL_DIR:?set KERNEL_DIR}"
: "${KERNEL_RELEASE:?set KERNEL_RELEASE}"
: "${OUT_DIR:?set OUT_DIR}"
: "${CHANNEL_DTB:?set CHANNEL_DTB}"

KERNEL="$KERNEL_DIR/arch/arm64/boot/Image.gz"
INITRD="$OUT_DIR/initrd.img-$KERNEL_RELEASE"
KERNEL_DTB="$OUT_DIR/Image.gz-dtb-$KERNEL_RELEASE"
BOOTIMG="$OUT_DIR/boot-channel.img"

test -s "$KERNEL"
test -s "$CHANNEL_DTB"
test -s "$INITRD"

cat "$KERNEL" "$CHANNEL_DTB" > "$KERNEL_DTB"

CMDLINE='root=LABEL=debian-rootfs rootfstype=ext4 rootwait rw console=ttyMSM0,115200 loglevel=7 ignore_loglevel panic=10 usbcore.autosuspend=-1'

mkbootimg   --header_version 0   --kernel "$KERNEL_DTB"   --ramdisk "$INITRD"   --cmdline "$CMDLINE"   --base 0x80000000   --kernel_offset 0x00008000   --ramdisk_offset 0x01000000   --second_offset 0x00f00000   --tags_offset 0x00000100   --pagesize 2048   --output "$BOOTIMG"

BOOT_SIZE="$(stat -c %s "$BOOTIMG")"
if [ "$BOOT_SIZE" -gt $((48 * 1024 * 1024)) ]; then
  echo "boot-channel.img is too large for the conservative lk2nd boot-memory budget: $BOOT_SIZE bytes" >&2
  exit 1
fi

printf '%s\n' "$CMDLINE" > "$OUT_DIR/kernel-cmdline.txt"
echo "boot-channel.img: $BOOT_SIZE bytes"
