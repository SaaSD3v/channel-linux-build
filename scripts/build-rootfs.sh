#!/usr/bin/env bash
set -euo pipefail

: "${KERNEL_RELEASE:?set KERNEL_RELEASE}"
: "${OUT_DIR:?set OUT_DIR}"

CHANNEL_ROOT_UUID="${CHANNEL_ROOT_UUID:-89530000-6320-4000-8000-000000000001}"

KERNEL_DIR="${KERNEL_DIR:-}"
KERNEL_MODULES_ARCHIVE="${KERNEL_MODULES_ARCHIVE:-}"
KERNEL_CONFIG_FILE="${KERNEL_CONFIG_FILE:-}"
KERNEL_SYSTEM_MAP_FILE="${KERNEL_SYSTEM_MAP_FILE:-}"
if [ -z "$KERNEL_MODULES_ARCHIVE" ] && [ -z "$KERNEL_DIR" ]; then
  echo "set KERNEL_MODULES_ARCHIVE or KERNEL_DIR" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-$REPO_ROOT/.work}"
ROOTFS="$WORK_DIR/rootfs"
KREL="$KERNEL_RELEASE"

mkdir -p "$WORK_DIR" "$OUT_DIR"
sudo rm -rf "$ROOTFS"

echo "::group::Create Debian 13 (trixie) arm64 rootfs"
sudo mmdebstrap \
  --architectures=arm64 \
  --variant=minbase \
  --components=main \
  --keyring=/usr/share/keyrings/debian-archive-keyring.gpg \
  --aptopt='Apt::Install-Recommends "false"' \
  --include=debian-archive-keyring,systemd-sysv,openssh-server,iproute2,iputils-ping,dnsmasq,ca-certificates,kmod,udev,busybox-static,e2fsprogs,util-linux,procps,less,nano,ethtool,openssh-client,iw,wpasupplicant,wireless-regdb,dbus,network-manager,systemd-timesyncd \
  trixie "$ROOTFS" https://deb.debian.org/debian
echo "::endgroup::"

echo "::group::Install channel headless configuration"
sudo cp -a "$REPO_ROOT/rootfs/." "$ROOTFS/"
sudo chmod 0755 "$ROOTFS/usr/local/sbin/channel-usb-gadget"
sudo chmod 0755 "$ROOTFS/usr/local/sbin/channel-wifi-firmware"

printf '%s\n' channel | sudo tee "$ROOTFS/etc/hostname" >/dev/null
sudo tee "$ROOTFS/etc/hosts" >/dev/null <<'EOF'
127.0.0.1 localhost
127.0.1.1 channel
::1 localhost ip6-localhost ip6-loopback
EOF

sudo tee "$ROOTFS/etc/fstab" >/dev/null <<'FSTAB'
UUID=89530000-6320-4000-8000-000000000001 / ext4 rw,noatime 0 1
FSTAB

# The rootfs uses one fixed SSH access method: root over USB RNDIS.
# Keep local root password non-empty; only SSH PAM allows empty authentication.
RANDOM_PASSWORD="$(openssl rand -hex 48)"
ROOT_HASH="$(openssl passwd -6 "$RANDOM_PASSWORD")"
sudo sed -i "s|^root:[^:]*:|root:${ROOT_HASH}:|" "$ROOTFS/etc/shadow"
unset RANDOM_PASSWORD ROOT_HASH
sudo tee "$ROOTFS/etc/pam.d/sshd" >/dev/null <<'PAM'
auth required pam_permit.so
account required pam_permit.so
session required pam_permit.so
PAM
if ! sudo grep -Fq 'Include /etc/ssh/sshd_config.d/*.conf' "$ROOTFS/etc/ssh/sshd_config"; then
  sudo sed -i '1iInclude /etc/ssh/sshd_config.d/*.conf' "$ROOTFS/etc/ssh/sshd_config"
fi

sudo ssh-keygen -A -f "$ROOTFS"

# Keep SSH under ssh.service control. Debian also ships ssh.socket, which
# listens independently from sshd's ListenAddress when explicitly enabled.
sudo systemctl --root="$ROOTFS" disable ssh.socket 2>/dev/null || true
sudo systemctl --root="$ROOTFS" disable dnsmasq.service 2>/dev/null || true
sudo systemctl --root="$ROOTFS" enable \
  channel-usb-gadget.service channel-dhcp.service \
  channel-wifi-firmware.service NetworkManager.service dbus.socket systemd-timesyncd.service

sudo systemctl --root="$ROOTFS" enable ssh.service

# Keep a persistent time floor. systemd-timesyncd advances this after a
# successful sync, preventing the broken device RTC from dropping back to 1970.
sudo install -d -m 0755 "$ROOTFS/var/lib/systemd/timesync"
sudo touch "$ROOTFS/var/lib/systemd/timesync/clock"

# This device is intentionally headless. Persist the journal so boot/USB
# failures can be inspected by mounting the microSD on another machine.
sudo mkdir -p "$ROOTFS/var/log/journal"
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

echo "::group::Finalize Debian rootfs"
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

sudo install -d -m 0755 "$ROOTFS/run/sshd"
sudo chroot "$ROOTFS" /usr/sbin/sshd -t

cleanup_mounts
trap - EXIT

# qemu-aarch64-static is a host-side helper and must not ship in the target image.
sudo rm -f "$ROOTFS/usr/bin/qemu-aarch64-static"
echo "::endgroup::"

echo "::group::Create ext4 rootfs image"
USED_MB="$(sudo du -sm "$ROOTFS" | awk '{print $1}')"
IMAGE_MB=$((USED_MB + 700))
if [ "$IMAGE_MB" -lt 1536 ]; then IMAGE_MB=1536; fi

ROOTFS_IMG="$OUT_DIR/rootfs.ext4"
truncate -s "${IMAGE_MB}M" "$ROOTFS_IMG"
sudo mkfs.ext4 -F -m 0 -L rootfs -U "$CHANNEL_ROOT_UUID" -d "$ROOTFS" "$ROOTFS_IMG"
sudo e2fsck -fn "$ROOTFS_IMG"
test "$(blkid -p -o value -s UUID "$ROOTFS_IMG")" = "$CHANNEL_ROOT_UUID"
test "$(blkid -p -o value -s LABEL "$ROOTFS_IMG")" = "rootfs"
zstd -T0 -10 -f "$ROOTFS_IMG" -o "$ROOTFS_IMG.zst"
rm -f "$ROOTFS_IMG"
echo "::endgroup::"

{
  echo "debian_suite=trixie"
  echo "kernel_release=$KREL"
  echo "rootfs_label=rootfs"
  echo "rootfs_uuid=$CHANNEL_ROOT_UUID"
  echo "usb_device_ip=172.16.42.1"
  echo "usb_dhcp_range=172.16.42.2-172.16.42.20"
  echo "ssh_auth=ssh"
  echo "ssh_listen=172.16.42.1"
  echo "ssh_scope=usb-only"
  echo "wifi_manager=NetworkManager"
  echo "usb_network_manager=unmanaged"
  echo "wifi_runtime_setup=nmcli"
  echo "wifi_firmware=stock-modem-vendor-readonly"
  echo "time_sync=systemd-timesyncd"
} > "$OUT_DIR/build-info.txt"
