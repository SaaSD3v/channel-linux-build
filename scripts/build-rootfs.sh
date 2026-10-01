#!/usr/bin/env bash
set -euo pipefail

: "${KERNEL_DIR:?set KERNEL_DIR}"
: "${KERNEL_RELEASE:?set KERNEL_RELEASE}"
: "${OUT_DIR:?set OUT_DIR}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-$REPO_ROOT/.work}"
ROOTFS="$WORK_DIR/rootfs"
KREL="$KERNEL_RELEASE"

mkdir -p "$WORK_DIR" "$OUT_DIR"
sudo rm -rf "$ROOTFS"

echo "::group::Create Debian 13 (trixie) arm64 rootfs"
sudo mmdebstrap   --architectures=arm64   --variant=minbase   --components=main   --aptopt='Apt::Install-Recommends "false"'   --include=systemd-sysv,openssh-server,iproute2,iputils-ping,dnsmasq,ca-certificates,kmod,udev,initramfs-tools,busybox-static,e2fsprogs,util-linux,procps,less,nano,ethtool,openssh-client   trixie "$ROOTFS" http://deb.debian.org/debian
echo "::endgroup::"

echo "::group::Install channel headless configuration"
sudo cp -a "$REPO_ROOT/rootfs/." "$ROOTFS/"
sudo chmod 0755 "$ROOTFS/usr/local/sbin/channel-usb-gadget"

printf '%s\n' channel | sudo tee "$ROOTFS/etc/hostname" >/dev/null
sudo tee "$ROOTFS/etc/hosts" >/dev/null <<'EOF'
127.0.0.1 localhost
127.0.1.1 channel
::1 localhost ip6-localhost ip6-loopback
EOF

sudo mkdir -p "$ROOTFS/root/.ssh"
KEYFILE="$WORK_DIR/authorized_key"
if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
  printf '%s\n' "$SSH_PUBLIC_KEY" | tr -d '\r' > "$KEYFILE"
  ssh-keygen -l -f "$KEYFILE" >/dev/null
  echo "Using SSH_PUBLIC_KEY from GitHub Actions secret."
else
  rm -f "$OUT_DIR/channel_test_ed25519" "$OUT_DIR/channel_test_ed25519.pub"
  ssh-keygen -q -t ed25519 -N "" -C "channel-bringup-ci" -f "$OUT_DIR/channel_test_ed25519"
  cp "$OUT_DIR/channel_test_ed25519.pub" "$KEYFILE"
  echo "No SSH_PUBLIC_KEY secret: generated an isolated bring-up key."
fi
sudo install -m 0600 -o root -g root "$KEYFILE" "$ROOTFS/root/.ssh/authorized_keys"
sudo chmod 0700 "$ROOTFS/root/.ssh"

# Keep the root account valid for public-key auth, but make its password
# unknown and disable all SSH password authentication in sshd_config.
RANDOM_PASSWORD="$(openssl rand -hex 48)"
ROOT_HASH="$(openssl passwd -6 "$RANDOM_PASSWORD")"
sudo sed -i "s|^root:[^:]*:|root:${ROOT_HASH}:|" "$ROOTFS/etc/shadow"
unset RANDOM_PASSWORD ROOT_HASH

sudo ssh-keygen -A -f "$ROOTFS"
sudo systemctl --root="$ROOTFS" disable dnsmasq.service 2>/dev/null || true
sudo systemctl --root="$ROOTFS" enable channel-usb-gadget.service channel-dhcp.service ssh.service
echo "::endgroup::"

echo "::group::Install mainline kernel modules"
sudo env PATH="$PATH" make -C "$KERNEL_DIR" ARCH=arm64 INSTALL_MOD_PATH="$ROOTFS" modules_install
sudo depmod -b "$ROOTFS" "$KREL"
sudo mkdir -p "$ROOTFS/boot"
sudo cp "$KERNEL_DIR/.config" "$ROOTFS/boot/config-$KREL"
if [ -f "$KERNEL_DIR/System.map" ]; then
  sudo cp "$KERNEL_DIR/System.map" "$ROOTFS/boot/System.map-$KREL"
fi
echo "::endgroup::"

echo "::group::Generate small Debian initramfs"
sudo tee "$ROOTFS/etc/initramfs-tools/initramfs.conf" >/dev/null <<'EOF'
MODULES=dep
BUSYBOX=y
KEYMAP=n
COMPRESS=gzip
DEVICE=
NFSROOT=auto
RUNSIZE=10%
EOF

# Storage and ext4 are intentionally required built-in by build-kernel.sh.
# Do not force built-in drivers into initramfs-tools' module list.
sudo tee "$ROOTFS/etc/initramfs-tools/modules" >/dev/null <<'EOF'
# channel: no forced modules; critical root-storage drivers are built into the kernel
EOF

sudo update-binfmts --enable qemu-aarch64 || true
if [ -x /usr/bin/qemu-aarch64-static ]; then
  sudo install -m 0755 /usr/bin/qemu-aarch64-static "$ROOTFS/usr/bin/qemu-aarch64-static"
fi

cleanup_mounts() {
  sudo umount -R "$ROOTFS/dev" 2>/dev/null || true
  sudo umount "$ROOTFS/proc" 2>/dev/null || true
  sudo umount "$ROOTFS/sys" 2>/dev/null || true
}
trap cleanup_mounts EXIT

sudo mount --bind /dev "$ROOTFS/dev"
sudo mount -t proc proc "$ROOTFS/proc"
sudo mount -t sysfs sysfs "$ROOTFS/sys"

sudo chroot "$ROOTFS" /bin/sh -c "depmod '$KREL'; update-initramfs -c -k '$KREL'"

cleanup_mounts
trap - EXIT

# qemu-aarch64-static is a host-side helper and must not ship in the target image.
sudo rm -f "$ROOTFS/usr/bin/qemu-aarch64-static"

sudo cp "$ROOTFS/boot/initrd.img-$KREL" "$OUT_DIR/initrd.img-$KREL"
INITRD_SIZE="$(stat -c %s "$OUT_DIR/initrd.img-$KREL")"
if [ "$INITRD_SIZE" -gt $((48 * 1024 * 1024)) ]; then
  echo "initramfs is unexpectedly large: $INITRD_SIZE bytes" >&2
  exit 1
fi
echo "initramfs: $INITRD_SIZE bytes"
echo "::endgroup::"

echo "::group::Create ext4 rootfs image"
USED_MB="$(sudo du -sm "$ROOTFS" | awk '{print $1}')"
IMAGE_MB=$((USED_MB + 700))
if [ "$IMAGE_MB" -lt 1536 ]; then IMAGE_MB=1536; fi

ROOTFS_IMG="$OUT_DIR/debian-channel-rootfs.ext4"
truncate -s "${IMAGE_MB}M" "$ROOTFS_IMG"
sudo mkfs.ext4 -F -m 0 -L debian-rootfs -d "$ROOTFS" "$ROOTFS_IMG"
sudo e2fsck -fn "$ROOTFS_IMG"
zstd -T0 -10 -f "$ROOTFS_IMG" -o "$ROOTFS_IMG.zst"
rm -f "$ROOTFS_IMG"
echo "::endgroup::"

{
  echo "debian_suite=trixie"
  echo "kernel_release=$KREL"
  echo "rootfs_label=debian-rootfs"
  echo "usb_device_ip=172.16.42.1"
  echo "usb_dhcp_range=172.16.42.2-172.16.42.20"
  echo "ssh_auth=public-key-only"
} > "$OUT_DIR/build-info.txt"
