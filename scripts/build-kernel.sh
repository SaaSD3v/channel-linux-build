#!/usr/bin/env bash
set -euo pipefail

: "${KERNEL_DIR:?set KERNEL_DIR}"
: "${OUT_DIR:?set OUT_DIR}"

JOBS="${JOBS:-$(nproc)}"

cd "$KERNEL_DIR"

mkdir -p "$OUT_DIR"

echo "::group::Configure kernel"
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig
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
  CONFIG_USB_CONFIGFS_RNDIS
  CONFIG_NET
  CONFIG_INET
  CONFIG_WLAN
  CONFIG_WLAN_VENDOR_ATH
  CONFIG_RPMSG_QCOM_SMD
  CONFIG_QCOM_SMEM
  CONFIG_QCOM_SMP2P
  CONFIG_QCOM_SMSM
)

for sym in "${required_y[@]}"; do
  if ! grep -qx "${sym}=y" .config; then
    echo "Required kernel option is not built-in: $sym" >&2
    grep -E "^${sym}=|^# ${sym} is not set" .config || true
    exit 1
  fi
done

required_m=(
  CONFIG_USB_CONFIGFS
  CONFIG_CFG80211
  CONFIG_MAC80211
  CONFIG_WCN36XX
  CONFIG_QCOM_WCNSS_PIL
  CONFIG_QCOM_WCNSS_CTRL
)

for sym in "${required_m[@]}"; do
  if ! grep -qx "${sym}=m" .config; then
    echo "Required kernel option is not a module: $sym" >&2
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
KREL="$(make -s ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- kernelrelease)"
if [ -z "$KREL" ]; then
  echo "Failed to resolve kernel release" >&2
  exit 1
fi
case "$KREL" in
  *-dirty)
    echo "Refusing dirty kernel release: $KREL" >&2
    exit 1
    ;;
esac
make -j"$JOBS" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KERNELRELEASE="$KREL" Image.gz dtbs modules
echo "::endgroup::"

DTB="arch/arm64/boot/dts/qcom/sdm632-motorola-channel.dtb"
if [ ! -s "$DTB" ]; then
  echo "Expected channel DTB was not produced: $DTB" >&2
  echo "SDM632/Motorola DTB candidates in this tree:" >&2
  find arch/arm64/boot/dts/qcom -maxdepth 1 -type f \( -name '*sdm632*' -o -name '*motorola*' -o -name '*channel*' \) -print >&2 || true
  exit 1
fi

mkdir -p "$OUT_DIR"
cp arch/arm64/boot/Image.gz "$OUT_DIR/Image.gz-$KREL"
cp "$DTB" "$OUT_DIR/sdm632-motorola-channel.dtb"
cp .config "$OUT_DIR/kernel.config-$KREL"
printf '%s\n' "$KREL" > "$OUT_DIR/kernel-release.txt"
git rev-parse HEAD > "$OUT_DIR/kernel-git-revision.txt"

echo "KERNEL_RELEASE=$KREL" >> "$GITHUB_ENV"
echo "CHANNEL_DTB=$KERNEL_DIR/$DTB" >> "$GITHUB_ENV"
echo "Kernel release: $KREL"
