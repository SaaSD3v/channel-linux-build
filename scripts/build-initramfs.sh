#!/usr/bin/env bash
set -euo pipefail

: "${BUSYBOX_BIN:?set BUSYBOX_BIN}"
: "${OUT_DIR:?set OUT_DIR}"

CHANNEL_ROOT_UUID="${CHANNEL_ROOT_UUID:-89530000-6320-4000-8000-000000000001}"
WORK_DIR="${WORK_DIR:-$OUT_DIR/.initramfs-work}"
ROOT="$WORK_DIR/root"
IMAGE="$OUT_DIR/initramfs-channel.cpio.gz"

command -v cpio >/dev/null
command -v gzip >/dev/null
command -v file >/dev/null

test -s "$BUSYBOX_BIN"
file "$BUSYBOX_BIN" | grep -Eq 'ARM aarch64|ARM64'
file "$BUSYBOX_BIN" | grep -qi 'statically linked'

rm -rf "$ROOT"
mkdir -p "$ROOT"/{bin,sbin,dev,proc,sys,run,newroot,etc}
install -m 0755 "$BUSYBOX_BIN" "$ROOT/bin/busybox"
ln -s busybox "$ROOT/bin/sh"
ln -s ../bin/busybox "$ROOT/sbin/mdev"

cat > "$ROOT/init" <<INIT
#!/bin/sh
BB=/bin/busybox
PATH=/bin:/sbin
ROOT_UUID="89530000-6320-4000-8000-000000000001"
export PATH

"$BB" mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
exec </dev/console >/dev/console 2>&1

log() {
    "$BB" echo "[channel-initramfs] $*"
    "$BB" echo "<6>[channel-initramfs] $*" > /dev/kmsg 2>/dev/null || true
}

fail_shell() {
    log "FALHA: $*"
    log "Shell de emergencia em /dev/console."
    exec /bin/sh
}

"$BB" mount -t proc proc /proc || fail_shell "nao foi possivel montar /proc"
"$BB" mount -t sysfs sysfs /sys || fail_shell "nao foi possivel montar /sys"
"$BB" mount -t tmpfs tmpfs /run 2>/dev/null || true
"$BB" mkdir -p /newroot

log "initramfs iniciado"
log "rootfs fixo: UUID=$ROOT_UUID LABEL=rootfs"

"$BB" mdev -s
"$BB" echo /sbin/mdev > /proc/sys/kernel/hotplug 2>/dev/null || true

ROOTDEV=""
tries=0
while [ "$tries" -lt 60 ]; do
    "$BB" mdev -s 2>/dev/null || true
    MATCHES=""

    for dev in /dev/mmcblk*p* /dev/mmcblk[0-9] /dev/sd[a-z][0-9]* /dev/sd[a-z] /dev/nvme*n*p*; do
        [ -b "$dev" ] || continue
        info="$("$BB" blkid "$dev" 2>/dev/null || true)"
        case "$info" in
            *"UUID=\"$ROOT_UUID\""*"TYPE=\"ext4\""*)
                MATCHES="$MATCHES $dev"
                ;;
            *"TYPE=\"ext4\""*"UUID=\"$ROOT_UUID\""*)
                MATCHES="$MATCHES $dev"
                ;;
        esac
    done

    set -- $MATCHES
    if [ "$#" -eq 1 ]; then
        ROOTDEV="$1"
        break
    elif [ "$#" -gt 1 ]; then
        log "UUID duplicado encontrado em:$MATCHES"
        fail_shell "mais de um dispositivo possui o UUID fixo"
    fi

    tries=$((tries + 1))
    if [ $((tries % 5)) -eq 0 ]; then
        log "aguardando UUID=$ROOT_UUID (${tries}s)"
    fi
    "$BB" sleep 1
done

[ -n "$ROOTDEV" ] || fail_shell "rootfs UUID=$ROOT_UUID nao encontrado"

log "rootfs encontrado: $ROOTDEV"
"$BB" mount -t ext4 -o rw "$ROOTDEV" /newroot ||
    fail_shell "falha ao montar $ROOTDEV"

if ! { [ -x /newroot/sbin/init ] || [ -L /newroot/sbin/init ]; }; then
    fail_shell "UUID correto encontrado, mas /sbin/init nao existe"
fi

if [ ! -f /newroot/etc/os-release ] && [ ! -f /newroot/usr/lib/os-release ]; then
    fail_shell "UUID correto encontrado, mas os-release nao existe"
fi

KREL="$("$BB" uname -r)"
if [ -d "/newroot/lib/modules/$KREL" ]; then
    log "modulos correspondentes encontrados: $KREL"
else
    log "AVISO: /lib/modules/$KREL nao existe no rootfs"
fi

for p in dev proc sys run; do
    "$BB" mkdir -p "/newroot/$p"
    "$BB" mount --move "/$p" "/newroot/$p" 2>/dev/null || true
done

log "executando switch_root -> /sbin/init"
exec /bin/busybox switch_root /newroot /sbin/init
fail_shell "switch_root retornou inesperadamente"
INIT

chmod 0755 "$ROOT/init"

(
  cd "$ROOT"
  find . -print0 | sort -z | cpio --null -o --format=newc --owner=0:0 2>/dev/null | gzip -9n > "$IMAGE"
)

test -s "$IMAGE"
gzip -t "$IMAGE"
gzip -dc "$IMAGE" | cpio -it 2>/dev/null | grep -qx '\./init'
gzip -dc "$IMAGE" | cpio -it 2>/dev/null | grep -qx '\./bin/busybox'

{
  echo "initramfs=initramfs-channel.cpio.gz"
  echo "rootfs_label=rootfs"
  echo "rootfs_uuid=$CHANNEL_ROOT_UUID"
  echo "root_locator=fixed-filesystem-uuid"
  echo "busybox=$(file "$BUSYBOX_BIN")"
  echo "initramfs_bytes=$(stat -c %s "$IMAGE")"
} > "$OUT_DIR/initramfs-report.txt"

echo "initramfs: $IMAGE"
