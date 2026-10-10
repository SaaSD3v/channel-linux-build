#!/usr/bin/env bash
set -euo pipefail

: "${KERNEL_RELEASE:?set KERNEL_RELEASE}"
: "${OUT_DIR:?set OUT_DIR}"


KERNEL_DIR="${KERNEL_DIR:-}"
KERNEL_MODULES_ARCHIVE="${KERNEL_MODULES_ARCHIVE:-}"
KERNEL_CONFIG_FILE="${KERNEL_CONFIG_FILE:-}"
KERNEL_SYSTEM_MAP_FILE="${KERNEL_SYSTEM_MAP_FILE:-}"
ALPINE_VERSION="${ALPINE_VERSION:-3.24.2}"
ALPINE_BRANCH="${ALPINE_BRANCH:-v${ALPINE_VERSION%.*}}"
ALPINE_MIRROR="${ALPINE_MIRROR:-https://dl-cdn.alpinelinux.org/alpine}"
ALPINE_ARCH="${ALPINE_ARCH:-aarch64}"
APK_TOOLS_STATIC_VERSION="${APK_TOOLS_STATIC_VERSION:-3.0.8-r0}"

if [ -z "$KERNEL_MODULES_ARCHIVE" ] && [ -z "$KERNEL_DIR" ]; then
  echo "set KERNEL_MODULES_ARCHIVE or KERNEL_DIR" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-$REPO_ROOT/.work}"
ROOTFS="$WORK_DIR/rootfs"
KREL="$KERNEL_RELEASE"
MINIROOTFS="alpine-minirootfs-${ALPINE_VERSION}-${ALPINE_ARCH}.tar.gz"
MINIROOTFS_URL="${ALPINE_MIRROR}/${ALPINE_BRANCH}/releases/${ALPINE_ARCH}/${MINIROOTFS}"
MINIROOTFS_PATH="$WORK_DIR/$MINIROOTFS"
MINIROOTFS_SHA_PATH="$MINIROOTFS_PATH.sha256"

mkdir -p "$WORK_DIR" "$OUT_DIR"
sudo rm -rf "$ROOTFS"
sudo mkdir -p "$ROOTFS"

echo "::group::Create Alpine ${ALPINE_VERSION} ${ALPINE_ARCH} rootfs"
curl -fsSL --retry 3 "$MINIROOTFS_URL" -o "$MINIROOTFS_PATH"
curl -fsSL --retry 3 "$MINIROOTFS_URL.sha256" -o "$MINIROOTFS_SHA_PATH"
(
  cd "$WORK_DIR"
  sha256sum -c "$(basename "$MINIROOTFS_SHA_PATH")"
)
sudo tar --numeric-owner -xzf "$MINIROOTFS_PATH" -C "$ROOTFS"

sudo tee "$ROOTFS/etc/apk/repositories" >/dev/null <<EOF
${ALPINE_MIRROR}/${ALPINE_BRANCH}/main
${ALPINE_MIRROR}/${ALPINE_BRANCH}/community
EOF

sudo cp -L /etc/resolv.conf "$ROOTFS/etc/resolv.conf"
if [ -x /usr/bin/qemu-aarch64-static ]; then
  sudo install -m 0755 /usr/bin/qemu-aarch64-static "$ROOTFS/usr/bin/qemu-aarch64-static"
fi

APK_STATIC_PKG="$WORK_DIR/apk-tools-static-$APK_TOOLS_STATIC_VERSION.apk"
APK_STATIC_DIR="$WORK_DIR/apk-static"
APK_STATIC_URL="$ALPINE_MIRROR/$ALPINE_BRANCH/main/x86_64/apk-tools-static-$APK_TOOLS_STATIC_VERSION.apk"

rm -rf "$APK_STATIC_DIR"
mkdir -p "$APK_STATIC_DIR"
curl -fsSL --retry 3 "$APK_STATIC_URL" -o "$APK_STATIC_PKG"
tar -xzf "$APK_STATIC_PKG" -C "$APK_STATIC_DIR" sbin/apk.static
APK_STATIC="$APK_STATIC_DIR/sbin/apk.static"
test -x "$APK_STATIC"

# Package scripts/triggers run in the target root. Give them the normal /dev
# interface temporarily (notably /dev/null and getrandom consumers) without
# copying host device nodes into the final filesystem image.
cleanup_apk_dev() {
  sudo umount "$ROOTFS/dev" 2>/dev/null || true
}
trap cleanup_apk_dev EXIT
sudo mkdir -p "$ROOTFS/dev"
sudo mount --bind /dev "$ROOTFS/dev"

# Use the native static apk binary to perform package file operations. Target
# package scripts still run inside the aarch64 root through binfmt/QEMU, but
# ownership/mode/SUID handling is no longer emulated. This avoids QEMU failing
# while apk preserves dbus-daemon-launch-helper permissions.
sudo "$APK_STATIC" \
  --root "$ROOTFS" \
  --arch "$ALPINE_ARCH" \
  --keys-dir etc/apk/keys \
  -X "$ALPINE_MIRROR/$ALPINE_BRANCH/main" \
  -X "$ALPINE_MIRROR/$ALPINE_BRANCH/community" \
  --update-cache add \
    openrc busybox-openrc \
    eudev eudev-openrc udev-init-scripts udev-init-scripts-openrc \
    openssh-server openssh-client \
    iproute2 \
    dnsmasq dnsmasq-openrc \
    ca-certificates \
    kmod \
    e2fsprogs \
    procps \
    less nano \
    ethtool iw \
    dbus dbus-openrc \
    networkmanager networkmanager-openrc networkmanager-cli networkmanager-wifi \
    wpa_supplicant wireless-regdb \
    openssl

sudo chroot "$ROOTFS" /usr/sbin/update-ca-certificates
echo "::endgroup::"

echo "::group::Install Channel Alpine headless configuration"
sudo cp -a "$REPO_ROOT/rootfs/." "$ROOTFS/"
sudo chmod 0755 \
  "$ROOTFS/usr/local/sbin/channel-usb-gadget" \
  "$ROOTFS/usr/local/sbin/channel-wifi-firmware" \
  "$ROOTFS/etc/init.d/channel-usb-gadget" \
  "$ROOTFS/etc/init.d/channel-sshd" \
  "$ROOTFS/etc/init.d/channel-wifi-firmware"

sudo install -d -m 0755 "$ROOTFS/etc/ssh/sshd_config.d"

printf '%s\n' channel | sudo tee "$ROOTFS/etc/hostname" >/dev/null
sudo tee "$ROOTFS/etc/hosts" >/dev/null <<'EOF'
127.0.0.1 localhost
127.0.1.1 channel
::1 localhost ip6-localhost ip6-loopback
EOF

sudo tee "$ROOTFS/etc/fstab" >/dev/null <<'EOF'
PARTLABEL=userdata / ext4 rw,noatime 0 1
EOF

# Keep a stable per-image identifier for the USB serial fallback.
if [ ! -s "$ROOTFS/etc/machine-id" ]; then
  openssl rand -hex 16 | sudo tee "$ROOTFS/etc/machine-id" >/dev/null
fi

# Fixed USB root SSH for Alpine without PAM; local gettys are disabled below.
sudo sed -i 's|^root:[^:]*:|root::|' "$ROOTFS/etc/shadow"
if ! sudo grep -Fq 'Include /etc/ssh/sshd_config.d/*.conf' "$ROOTFS/etc/ssh/sshd_config"; then
  sudo sed -i '1iInclude /etc/ssh/sshd_config.d/*.conf' "$ROOTFS/etc/ssh/sshd_config"
fi

sudo chroot "$ROOTFS" /usr/bin/ssh-keygen -A

# Build an explicit OpenRC runlevel set. NetworkManager on Alpine requires
# eudev; never run mdev and udev as competing device managers.
sudo chroot "$ROOTFS" /sbin/rc-update del mdev sysinit 2>/dev/null || true
for service in devfs dmesg udev udev-trigger udev-settle; do
  sudo chroot "$ROOTFS" /sbin/rc-update add "$service" sysinit
done
for service in hwdrivers modules sysctl hostname bootmisc syslog localmount; do
  sudo chroot "$ROOTFS" /sbin/rc-update add "$service" boot
done
for service in udev-postmount dbus channel-usb-gadget dnsmasq channel-sshd channel-wifi-firmware networkmanager; do
  sudo chroot "$ROOTFS" /sbin/rc-update add "$service" default
done


# NetworkManager owns wlan0 and launches the wpa_supplicant backend itself.
# Keep Alpine's legacy networking and standalone supplicant services disabled.
sudo chroot "$ROOTFS" /sbin/rc-update del networking boot 2>/dev/null || true
sudo chroot "$ROOTFS" /sbin/rc-update del wpa_supplicant boot 2>/dev/null || true

test -x "$ROOTFS/sbin/udevd"
test -L "$ROOTFS/etc/runlevels/sysinit/udev"
test -L "$ROOTFS/etc/runlevels/sysinit/udev-trigger"
test -L "$ROOTFS/etc/runlevels/sysinit/udev-settle"
test -L "$ROOTFS/etc/runlevels/default/udev-postmount"
test -L "$ROOTFS/etc/runlevels/default/networkmanager"
test ! -e "$ROOTFS/etc/runlevels/sysinit/mdev"
test ! -e "$ROOTFS/etc/runlevels/boot/networking"
test ! -e "$ROOTFS/etc/runlevels/boot/wpa_supplicant"
grep -Fqx 'unmanaged-devices=interface-name:usb0' "$ROOTFS/etc/NetworkManager/conf.d/10-channel.conf"
grep -Fqx 'wifi.backend=wpa_supplicant' "$ROOTFS/etc/NetworkManager/conf.d/10-channel.conf"

# This image is intentionally headless. Alpine's init spawns gettys from
# /etc/inittab, independently of OpenRC runlevel links. Remove both forms so
# USB SSH must not expose the empty Unix root password on a local/serial console.
sudo sed -i -E '/::(respawn|askfirst):.*(a?getty)/d' "$ROOTFS/etc/inittab"
sudo rm -f "$ROOTFS"/etc/runlevels/default/agetty.* "$ROOTFS"/etc/runlevels/default/consolefont 2>/dev/null || true
if grep -Eq '::(respawn|askfirst):.*(a?getty)' "$ROOTFS/etc/inittab"; then
  echo "Refusing an Alpine image with a local getty enabled" >&2
  exit 1
fi

# Keep persistent logs for headless bring-up.
sudo install -d -m 0755 "$ROOTFS/var/log"
echo "::endgroup::"

echo "::group::Install mainline kernel modules"
if [ -n "$KERNEL_MODULES_ARCHIVE" ]; then
  test -s "$KERNEL_MODULES_ARCHIVE"
  sudo tar -I zstd -xf "$KERNEL_MODULES_ARCHIVE" -C "$ROOTFS"
else
  sudo env PATH="$PATH" make -C "$KERNEL_DIR" ARCH=arm64 KERNELRELEASE="$KREL" INSTALL_MOD_PATH="$ROOTFS" modules_install
fi
sudo depmod -b "$ROOTFS" "$KREL"

sudo mkdir -p "$ROOTFS/boot"
if [ -n "$KERNEL_CONFIG_FILE" ] && [ -s "$KERNEL_CONFIG_FILE" ]; then
  sudo cp "$KERNEL_CONFIG_FILE" "$ROOTFS/boot/config-$KREL"
elif [ -n "$KERNEL_DIR" ] && [ -s "$KERNEL_DIR/.config" ]; then
  sudo cp "$KERNEL_DIR/.config" "$ROOTFS/boot/config-$KREL"
fi
if [ -n "$KERNEL_SYSTEM_MAP_FILE" ] && [ -s "$KERNEL_SYSTEM_MAP_FILE" ]; then
  sudo cp "$KERNEL_SYSTEM_MAP_FILE" "$ROOTFS/boot/System.map-$KREL"
elif [ -n "$KERNEL_DIR" ] && [ -f "$KERNEL_DIR/System.map" ]; then
  sudo cp "$KERNEL_DIR/System.map" "$ROOTFS/boot/System.map-$KREL"
fi
echo "::endgroup::"

echo "::group::Finalize Alpine rootfs"
sudo chroot "$ROOTFS" /usr/sbin/sshd -t

# qemu-aarch64-static is a host-side helper and must not ship in the target image.
sudo rm -f "$ROOTFS/usr/bin/qemu-aarch64-static"
echo "::endgroup::"

# All target chroot operations are complete. Remove the temporary host /dev
# bind before materializing the filesystem image.
cleanup_apk_dev
trap - EXIT

echo "::group::Create ext4 rootfs image"
USED_MB="$(sudo du -sm "$ROOTFS" | awk '{print $1}')"
IMAGE_MB=$((USED_MB + 512))
if [ "$IMAGE_MB" -lt 1024 ]; then IMAGE_MB=1024; fi

ROOTFS_IMG="$OUT_DIR/rootfs.ext4"
truncate -s "${IMAGE_MB}M" "$ROOTFS_IMG"
sudo mkfs.ext4 -F -m 0 -L rootfs -U random -d "$ROOTFS" "$ROOTFS_IMG"
sudo e2fsck -fn "$ROOTFS_IMG"
ROOTFS_EXT4_UUID="$(blkid -p -o value -s UUID "$ROOTFS_IMG")"
test -n "$ROOTFS_EXT4_UUID"
test "$(blkid -p -o value -s LABEL "$ROOTFS_IMG")" = "rootfs"
zstd -T0 -10 -f "$ROOTFS_IMG" -o "$ROOTFS_IMG.zst"
rm -f "$ROOTFS_IMG"
echo "::endgroup::"

{
  echo "distribution=alpine"
  echo "alpine_version=$ALPINE_VERSION"
  echo "alpine_branch=$ALPINE_BRANCH"
  echo "apk_tools_static_version=$APK_TOOLS_STATIC_VERSION"
  echo "kernel_release=$KREL"
  echo "rootfs_label=rootfs"
  echo "rootfs_uuid=$ROOTFS_EXT4_UUID"
  echo "init=openrc"
  echo "usb_device_ip=172.16.42.1"
  echo "usb_dhcp_range=172.16.42.2-172.16.42.20"
  echo "ssh_auth=ssh"
  echo "ssh_listen=172.16.42.1"
  echo "ssh_scope=usb-only"
  echo "wifi_manager=NetworkManager"
  echo "wifi_runtime_setup=nmcli"
  echo "usb_network_manager=unmanaged"
  echo "wifi_firmware=stock-modem-vendor-readonly"
} > "$OUT_DIR/build-info.txt"
