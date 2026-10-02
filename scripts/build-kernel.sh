#!/usr/bin/env bash
set -euo pipefail

: "${KERNEL_DIR:?set KERNEL_DIR}"
: "${OUT_DIR:?set OUT_DIR}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRAGMENT="$REPO_ROOT/config/channel-mainline.config"
JOBS="${JOBS:-$(nproc)}"

cd "$KERNEL_DIR"

echo "::group::Apply Channel Wi-Fi device-tree fix"
WIFI_PATCH="$REPO_ROOT/wcn3620-fix.patch"
if git apply --check "$WIFI_PATCH" 2>/dev/null; then
  git apply "$WIFI_PATCH"
elif git apply --reverse --check "$WIFI_PATCH"; then
  echo "Channel Wi-Fi patch is already applied."
else
  echo "Channel Wi-Fi patch does not match the kernel tree; refusing an unpatched build." >&2
  exit 1
fi
mkdir -p "$OUT_DIR"
cp "$WIFI_PATCH" "$OUT_DIR/wcn3620-fix.patch"
echo "::endgroup::"

echo "::group::Configure kernel"
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig
scripts/kconfig/merge_config.sh -m .config "$FRAGMENT"
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig

required_y=(
  CONFIG_BLK_DEV_INITRD
  CONFIG_RD_GZIP
  CONFIG_DEVTMPFS
  CONFIG_DEVTMPFS_MOUNT
  CONFIG_EXT4_FS
  CONFIG_MMC
  CONFIG_MMC_BLOCK
  CONFIG_MMC_SDHCI
  CONFIG_MMC_SDHCI_PLTFM
  CONFIG_MMC_SDHCI_MSM
  CONFIG_CONFIGFS_FS
  CONFIG_USB
  CONFIG_USB_DWC3
  CONFIG_USB_DWC3_QCOM
  CONFIG_USB_GADGET
  CONFIG_USB_CONFIGFS
  CONFIG_USB_CONFIGFS_RNDIS
  CONFIG_NET
  CONFIG_INET
)

for sym in "${required_y[@]}"; do
  if ! grep -qx "${sym}=y" .config; then
    echo "Required kernel option is not built-in: $sym" >&2
    grep -E "^${sym}=|^# ${sym} is not set" .config || true
    exit 1
  fi
done

if ! grep -qx 'CONFIG_USB_DWC3_DUAL_ROLE=y' .config &&    ! grep -qx 'CONFIG_USB_DWC3_GADGET=y' .config; then
  echo "DWC3 is not configured for gadget/dual-role operation" >&2
  exit 1
fi

echo "::endgroup::"

echo "::group::Build kernel, DTBs and modules"
make -j"$JOBS" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image.gz dtbs modules
echo "::endgroup::"

DTB="arch/arm64/boot/dts/qcom/sdm632-motorola-channel.dtb"
if [ ! -s "$DTB" ]; then
  echo "Expected channel DTB was not produced: $DTB" >&2
  echo "SDM632/Motorola DTB candidates in this tree:" >&2
  find arch/arm64/boot/dts/qcom -maxdepth 1 -type f \( -name '*sdm632*' -o -name '*motorola*' -o -name '*channel*' \) -print >&2 || true
  exit 1
fi

KREL="$(make -s ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- kernelrelease)"
mkdir -p "$OUT_DIR"
cp arch/arm64/boot/Image.gz "$OUT_DIR/Image.gz-$KREL"
cp "$DTB" "$OUT_DIR/sdm632-motorola-channel.dtb"
cp .config "$OUT_DIR/kernel.config-$KREL"
printf '%s\n' "$KREL" > "$OUT_DIR/kernel-release.txt"
git rev-parse HEAD > "$OUT_DIR/kernel-git-revision.txt"

echo "KERNEL_RELEASE=$KREL" >> "$GITHUB_ENV"
echo "CHANNEL_DTB=$KERNEL_DIR/$DTB" >> "$GITHUB_ENV"
echo "Kernel release: $KREL"
