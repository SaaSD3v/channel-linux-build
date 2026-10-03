#!/usr/bin/env bash
set -euo pipefail

: "${KERNEL_RELEASE:?set KERNEL_RELEASE}"
: "${OUT_DIR:?set OUT_DIR}"

KERNEL_DIR="${KERNEL_DIR:-}"
KERNEL_MODULES_ARCHIVE="${KERNEL_MODULES_ARCHIVE:-}"
KERNEL_CONFIG_FILE="${KERNEL_CONFIG_FILE:-}"
KERNEL_SYSTEM_MAP_FILE="${KERNEL_SYSTEM_MAP_FILE:-}"
WIFI_SSID="${WIFI_SSID:-}"
WIFI_PASSWORD="${WIFI_PASSWORD:-}"
WIFI_COUNTRY="${WIFI_COUNTRY:-}"
WIFI_AUTOCONNECT=0

ALPINE_VERSION="${ALPINE_VERSION:-3.24.2}"
ALPINE_BRANCH="${ALPINE_BRANCH:-v${ALPINE_VERSION%.*}}"
ALPINE_MIRROR="${ALPINE_MIRROR:-https://dl-cdn.alpinelinux.org/alpine}"
ALPINE_ARCH="${ALPINE_ARCH:-aarch64}"

if [ -n "$WIFI_SSID" ] || [ -n "$WIFI_PASSWORD" ]; then
  if [ -z "$WIFI_SSID" ] || [ -z "$WIFI_PASSWORD" ]; then
    echo "WIFI_SSID and WIFI_PASSWORD must both be set for Wi-Fi autoconnect" >&2
    exit 2
  fi
  WIFI_AUTOCONNECT=1
fi

if [ -n "$WIFI_COUNTRY" ]; then
  WIFI_COUNTRY="${WIFI_COUNTRY^^}"
  if [[ ! "$WIFI_COUNTRY" =~ ^[A-Z]{2}$ ]]; then
    echo "WIFI_COUNTRY must be a two-letter ISO country code" >&2
    exit 2
  fi
fi

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

sudo chroot "$ROOTFS" /bin/sh -ec '
  apk update
  apk add --no-cache \
    openrc busybox-openrc busybox-mdev-openrc \
    openssh-server openssh-client \
    iproute2 \
    dnsmasq \
    ca-certificates \
    kmod \
    e2fsprogs \
    procps \
    less nano \
    ethtool iw \
    wpa_supplicant wireless-regdb \
    chrony \
    mkinitfs \
    openssl
  update-ca-certificates
'
echo "::endgroup::"

echo "::group::Install Channel Alpine headless configuration"
sudo cp -a "$REPO_ROOT/rootfs/." "$ROOTFS/"
sudo chmod 0755 \
  "$ROOTFS/usr/local/sbin/channel-usb-gadget" \
  "$ROOTFS/usr/local/sbin/channel-wifi-firmware" \
  "$ROOTFS/usr/local/sbin/channel-wifi-dhcp" \
  "$ROOTFS/usr/local/sbin/channel-wifi" \
  "$ROOTFS/usr/local/libexec/channel-udhcpc" \
  "$ROOTFS/etc/init.d/channel-usb-gadget" \
  "$ROOTFS/etc/init.d/channel-dhcp" \
  "$ROOTFS/etc/init.d/channel-sshd" \
  "$ROOTFS/etc/init.d/channel-wifi"

sudo install -d -m 0755 "$ROOTFS/etc/wpa_supplicant" "$ROOTFS/etc/ssh/sshd_config.d"

printf '%s\n' channel | sudo tee "$ROOTFS/etc/hostname" >/dev/null
sudo tee "$ROOTFS/etc/hosts" >/dev/null <<'EOF'
127.0.0.1 localhost
127.0.1.1 channel
::1 localhost ip6-localhost ip6-loopback
EOF

sudo tee "$ROOTFS/etc/fstab" >/dev/null <<'EOF'
LABEL=alpine-rootfs / ext4 rw,noatime 0 1
EOF

# Keep a stable per-image identifier for the USB serial fallback.
if [ ! -s "$ROOTFS/etc/machine-id" ]; then
  openssl rand -hex 16 | sudo tee "$ROOTFS/etc/machine-id" >/dev/null
fi

SSH_AUTH_MODE="${SSH_AUTH_MODE:-auto}"
SSH_PUBLIC_KEY_INPUT="${SSH_PUBLIC_KEY_INPUT:-}"
SSH_PUBLIC_KEY="${SSH_PUBLIC_KEY:-}"
SSH_PASSWORD="${SSH_PASSWORD:-}"

rm -f "$OUT_DIR/channel_test_ed25519" "$OUT_DIR/channel_test_ed25519.pub" "$OUT_DIR/channel_ssh_password.txt"
sudo mkdir -p "$ROOTFS/root/.ssh"
sudo chmod 0700 "$ROOTFS/root/.ssh"
KEYFILE="$WORK_DIR/authorized_key"
rm -f "$KEYFILE"

ALLOW_KEY=0
ALLOW_PASSWORD=0
ALLOW_EMPTY_SSH=0
ROOT_PASSWORD=""

install_public_key() {
  printf '%s\n' "$1" | tr -d '\r' > "$KEYFILE"
  ssh-keygen -l -f "$KEYFILE" >/dev/null
  sudo install -m 0600 -o root -g root "$KEYFILE" "$ROOTFS/root/.ssh/authorized_keys"
  ALLOW_KEY=1
}

generate_public_key() {
  ssh-keygen -q -t ed25519 -N "" -C "channel-alpine-bringup-ci" -f "$OUT_DIR/channel_test_ed25519"
  install_public_key "$(cat "$OUT_DIR/channel_test_ed25519.pub")"
}

generate_password() {
  ROOT_PASSWORD="$(openssl rand -hex 24)"
  printf '%s\n' "$ROOT_PASSWORD" > "$OUT_DIR/channel_ssh_password.txt"
  chmod 0600 "$OUT_DIR/channel_ssh_password.txt"
  ALLOW_PASSWORD=1
}

case "$SSH_AUTH_MODE" in
  auto)
    if [ -n "$SSH_PUBLIC_KEY" ]; then
      install_public_key "$SSH_PUBLIC_KEY"
      SSH_AUTH_MODE="public-key-secret"
    else
      generate_public_key
      SSH_AUTH_MODE="generated-key"
    fi
    ;;
  generated-key)
    generate_public_key
    ;;
  public-key-input)
    [ -n "$SSH_PUBLIC_KEY_INPUT" ] || { echo "ssh_public_key input is required for public-key-input" >&2; exit 2; }
    install_public_key "$SSH_PUBLIC_KEY_INPUT"
    ;;
  public-key-secret)
    [ -n "$SSH_PUBLIC_KEY" ] || { echo "SSH_PUBLIC_KEY secret is required for public-key-secret" >&2; exit 2; }
    install_public_key "$SSH_PUBLIC_KEY"
    ;;
  generated-password)
    generate_password
    ;;
  password-secret)
    [ -n "$SSH_PASSWORD" ] || { echo "SSH_PASSWORD secret is required for password-secret" >&2; exit 2; }
    ROOT_PASSWORD="$SSH_PASSWORD"
    ALLOW_PASSWORD=1
    ;;
  generated-key+generated-password)
    generate_public_key
    generate_password
    ;;
  public-key-input+password-secret)
    [ -n "$SSH_PUBLIC_KEY_INPUT" ] || { echo "ssh_public_key input is required" >&2; exit 2; }
    [ -n "$SSH_PASSWORD" ] || { echo "SSH_PASSWORD secret is required" >&2; exit 2; }
    install_public_key "$SSH_PUBLIC_KEY_INPUT"
    ROOT_PASSWORD="$SSH_PASSWORD"
    ALLOW_PASSWORD=1
    ;;
  public-key-secret+password-secret)
    [ -n "$SSH_PUBLIC_KEY" ] || { echo "SSH_PUBLIC_KEY secret is required" >&2; exit 2; }
    [ -n "$SSH_PASSWORD" ] || { echo "SSH_PASSWORD secret is required" >&2; exit 2; }
    install_public_key "$SSH_PUBLIC_KEY"
    ROOT_PASSWORD="$SSH_PASSWORD"
    ALLOW_PASSWORD=1
    ;;
  open-root-usb)
    ALLOW_EMPTY_SSH=1
    ;;
  *)
    echo "Unsupported SSH_AUTH_MODE: $SSH_AUTH_MODE" >&2
    exit 2
    ;;
esac

if [ "$ALLOW_EMPTY_SSH" -eq 1 ]; then
  # Alpine OpenSSH is built without PAM by default. An empty root password is
  # therefore required for the SSH "none"/empty-password path. No getty is
  # enabled in this image, and sshd only listens on the USB RNDIS address.
  sudo sed -i 's|^root:[^:]*:|root::|' "$ROOTFS/etc/shadow"
elif [ "$ALLOW_PASSWORD" -eq 1 ]; then
  ROOT_HASH="$(openssl passwd -6 "$ROOT_PASSWORD")"
  sudo sed -i "s|^root:[^:]*:|root:${ROOT_HASH}:|" "$ROOTFS/etc/shadow"
  unset ROOT_HASH ROOT_PASSWORD
else
  RANDOM_PASSWORD="$(openssl rand -hex 48)"
  ROOT_HASH="$(openssl passwd -6 "$RANDOM_PASSWORD")"
  sudo sed -i "s|^root:[^:]*:|root:${ROOT_HASH}:|" "$ROOTFS/etc/shadow"
  unset RANDOM_PASSWORD ROOT_HASH
fi

if [ "$ALLOW_EMPTY_SSH" -eq 1 ]; then
  SSH_ROOT_LOGIN=yes
  SSH_PUBKEY=no
  SSH_PASSWORD_AUTH=yes
  SSH_EMPTY_PASSWORDS=yes
elif [ "$ALLOW_PASSWORD" -eq 1 ]; then
  SSH_ROOT_LOGIN=yes
  SSH_PUBKEY=$([ "$ALLOW_KEY" -eq 1 ] && echo yes || echo no)
  SSH_PASSWORD_AUTH=yes
  SSH_EMPTY_PASSWORDS=no
elif [ "$ALLOW_KEY" -eq 1 ]; then
  SSH_ROOT_LOGIN=prohibit-password
  SSH_PUBKEY=yes
  SSH_PASSWORD_AUTH=no
  SSH_EMPTY_PASSWORDS=no
else
  echo "No usable SSH authentication method selected" >&2
  exit 2
fi

sudo tee "$ROOTFS/etc/ssh/sshd_config.d/10-channel-usb.conf" >/dev/null <<EOF
ListenAddress 172.16.42.1
AllowUsers root
PermitRootLogin $SSH_ROOT_LOGIN
PubkeyAuthentication $SSH_PUBKEY
PasswordAuthentication $SSH_PASSWORD_AUTH
KbdInteractiveAuthentication no
PermitEmptyPasswords $SSH_EMPTY_PASSWORDS
UseDNS no
EOF

if ! sudo grep -Eq '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf' "$ROOTFS/etc/ssh/sshd_config"; then
  sudo sed -i '1iInclude /etc/ssh/sshd_config.d/*.conf' "$ROOTFS/etc/ssh/sshd_config"
fi

sudo chroot "$ROOTFS" /usr/bin/ssh-keygen -A

# Build an explicit OpenRC runlevel set. The minirootfs is not a setup-alpine
# installation, so services must be registered manually.
for service in devfs dmesg mdev; do
  sudo chroot "$ROOTFS" /sbin/rc-update add "$service" sysinit
done
for service in hwdrivers modules sysctl hostname bootmisc syslog localmount; do
  sudo chroot "$ROOTFS" /sbin/rc-update add "$service" boot
done
for service in chronyd channel-usb-gadget channel-dhcp channel-sshd channel-wifi; do
  sudo chroot "$ROOTFS" /sbin/rc-update add "$service" default
done

# This image is intentionally headless. Alpine's init spawns gettys from
# /etc/inittab, independently of OpenRC runlevel links. Remove both forms so
# open-root-usb cannot expose the empty root password on a local/serial console.
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

echo "::group::Generate Alpine initramfs"
sudo install -d -m 0755 "$ROOTFS/etc/mkinitfs"
sudo tee "$ROOTFS/etc/mkinitfs/mkinitfs.conf" >/dev/null <<'EOF'
features="base ext4"
EOF

# Channel's root-storage path is built into the kernel. Keep the early userspace
# independent of the distro's kernel-module packaging: mkinitfs only needs the
# base userspace to locate LABEL=alpine-rootfs and switch_root into it.
if [ -n "$KERNEL_CONFIG_FILE" ] && [ -s "$KERNEL_CONFIG_FILE" ]; then
  for option in CONFIG_EXT4_FS CONFIG_MMC CONFIG_MMC_BLOCK CONFIG_MMC_SDHCI CONFIG_MMC_SDHCI_PLTFM CONFIG_MMC_SDHCI_MSM; do
    grep -q "^$option=y$" "$KERNEL_CONFIG_FILE" || {
      echo "$option must be built-in when generating the module-free Channel initramfs" >&2
      exit 1
    }
  done
fi

if [ "$WIFI_AUTOCONNECT" -eq 1 ]; then
  set +x
  {
    echo 'ctrl_interface=/run/wpa_supplicant'
    echo 'update_config=0'
    if [ -n "$WIFI_COUNTRY" ]; then
      printf 'country=%s\n' "$WIFI_COUNTRY"
    fi
    printf '%s\n' "$WIFI_PASSWORD" | sudo chroot "$ROOTFS" /usr/bin/wpa_passphrase "$WIFI_SSID" | \
      sed '/^[[:space:]]*#psk=/d'
  } | sudo tee "$ROOTFS/etc/wpa_supplicant/wpa_supplicant-channel.conf" >/dev/null
  sudo chmod 0600 "$ROOTFS/etc/wpa_supplicant/wpa_supplicant-channel.conf"
  unset WIFI_PASSWORD
fi

sudo chroot "$ROOTFS" /usr/sbin/sshd -t
sudo chroot "$ROOTFS" /sbin/mkinitfs -n -c /etc/mkinitfs/mkinitfs.conf -b / -o "/boot/initramfs-$KREL" "$KREL"

INITRAMFS="$ROOTFS/boot/initramfs-$KREL"
test -s "$INITRAMFS"

# qemu-aarch64-static is a host-side helper and must not ship in the target image.
sudo rm -f "$ROOTFS/usr/bin/qemu-aarch64-static"
sudo cp "$INITRAMFS" "$OUT_DIR/initrd.img-$KREL"

INITRD_SIZE="$(stat -c %s "$OUT_DIR/initrd.img-$KREL")"
if [ "$INITRD_SIZE" -gt $((48 * 1024 * 1024)) ]; then
  echo "initramfs is unexpectedly large: $INITRD_SIZE bytes" >&2
  exit 1
fi
echo "initramfs: $INITRD_SIZE bytes"
echo "::endgroup::"

echo "::group::Create ext4 rootfs image"
USED_MB="$(sudo du -sm "$ROOTFS" | awk '{print $1}')"
IMAGE_MB=$((USED_MB + 512))
if [ "$IMAGE_MB" -lt 1024 ]; then IMAGE_MB=1024; fi

ROOTFS_IMG="$OUT_DIR/alpine-channel-rootfs.ext4"
truncate -s "${IMAGE_MB}M" "$ROOTFS_IMG"
sudo mkfs.ext4 -F -m 0 -L alpine-rootfs -d "$ROOTFS" "$ROOTFS_IMG"
sudo e2fsck -fn "$ROOTFS_IMG"
zstd -T0 -10 -f "$ROOTFS_IMG" -o "$ROOTFS_IMG.zst"
rm -f "$ROOTFS_IMG"
echo "::endgroup::"

{
  echo "distribution=alpine"
  echo "alpine_version=$ALPINE_VERSION"
  echo "alpine_branch=$ALPINE_BRANCH"
  echo "kernel_release=$KREL"
  echo "rootfs_label=alpine-rootfs"
  echo "init=openrc"
  echo "usb_device_ip=172.16.42.1"
  echo "usb_dhcp_range=172.16.42.2-172.16.42.20"
  echo "ssh_auth=$SSH_AUTH_MODE"
  echo "ssh_listen=172.16.42.1"
  echo "ssh_scope=usb-only"
  echo "wifi_autoconnect=$([ "$WIFI_AUTOCONNECT" -eq 1 ] && echo embedded || echo runtime-ready)"
  echo "wifi_runtime_config=/etc/wpa_supplicant/wpa_supplicant-channel.conf"
  echo "wifi_runtime_setup=wpa_passphrase"
  echo "wifi_firmware=stock-modem-vendor-readonly"
  echo "time_sync=chrony"
} > "$OUT_DIR/build-info.txt"
