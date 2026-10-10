# Moto G7 Play (channel) — Alpine mainline bring-up

---

## Canonical rootfs identity

All current Channel rootfs builds use one identity only:

- file: `rootfs.ext4.zst`
- ext4 label: `rootfs`
- ext4 UUID: `89530000-6320-4000-8000-000000000001`

The validated Channel kernel boot image has no initramfs. It mounts Android
`userdata` directly using `root=PARTUUID=76dbdefa-f243-cd22-5da5-9374e6ad318b`
and `rootfstype=ext4 rootwait rw`. The filesystem UUID above identifies the
rootfs image, not the boot partition locator.

This branch builds a headless Alpine Linux userspace for the Motorola Moto G7 Play (`channel`, Qualcomm SDM632) on the existing mainline kernel/lk2nd boot flow.

---

## What changed from `main`

The kernel, Channel DTB, WCN36xx fix, lk2nd, DTBO and Android boot-image layout stay the same. The userspace is Alpine Linux instead of Debian:

- Alpine 3.24.2 aarch64 minirootfs;
- OpenRC instead of systemd;
- Alpine `apk` packages for OpenSSH, `wpa_supplicant`, dnsmasq, networking and utilities;
- root filesystem label `rootfs`;
- rootfs artifact `rootfs.ext4.zst`.

The rootfs bootstrap verifies the official Alpine minirootfs SHA-256 before extracting it.

---

## Rootfs build

Use `.github/workflows/rootfs.yml` for the Alpine rootfs. It reuses a matching
kernel checkpoint where available, or builds the kernel as an internal module
dependency. The output is `rootfs.ext4.zst`, without a new boot image or
initramfs. The former integrated `build.yml` and its obsolete initramfs path
were removed; boot images are provided by the separate mainline kernel build.

---

## USB SSH

The USB gadget remains RNDIS with:

- device: `172.16.42.1/24`;
- DHCP range: `172.16.42.2` through `172.16.42.20`;
- sshd listening only on `172.16.42.1`.

OpenRC starts `channel-usb-gadget` first, then Alpine's packaged `dnsmasq` service and `channel-sshd`. The Windows host receives `172.16.42.2`–`172.16.42.20` by DHCP without manual IPv4 configuration.

SSH access has one fixed mode, `ssh`, without workflow credential inputs or
password/key artifacts. The intended command from a USB-connected computer is
`ssh root@172.16.42.1`. Alpine's OpenSSH in this image has no PAM; the builder
uses an empty Unix root password for USB SSH and disables local gettys. Treat
this as a development-only image and confirm isolation from Wi-Fi on hardware.

---

## Wi-Fi

The Channel WCNSS flow is preserved. `channel-wifi-firmware` mounts the stock
modem/vendor partitions read-only, exposes the WCNSS firmware/NV files, starts
`qcom_wcnss_pil`, then loads `wcn36xx`.

Alpine's packaged NetworkManager service owns `wlan0`, Wi-Fi association,
DHCP, routes, and DNS. The firmware service is ordered before NetworkManager.

Configure Wi-Fi at runtime with:

```sh
nmcli dev wifi list
nmcli dev wifi connect "<network-name>" password "<password>"
```

NetworkManager persists the connection profile for later boots. The old
Channel-specific supplicant, DHCP-client, config-watcher, and udhcpc helpers
are not used.

---

## Rootfs overlay

Project-owned Alpine runtime files live in `rootfs/`:

- `etc/init.d/` — Channel hardware/USB OpenRC services; Wi-Fi management itself uses Alpine's packaged `networkmanager` service;
- `etc/ssh/` — USB-only sshd policy;
- `etc/modprobe.d/` — WCNSS autoload ordering;
- `usr/local/sbin/` — the USB gadget and Channel WCNSS firmware helpers.

---

## Storage

The rootfs is a standalone ext4 image labeled `rootfs`. This repository still does not repartition or flash the phone automatically; placement of the ext4 image remains a separate device-side step.

---

## Imagem ext4 raw, Android sparse e expansão do `/`

**Somente para o rootfs desta branch.** O workflow gera `rootfs.ext4.zst` (ext4 raw comprimido). Depois de extrair o ZIP do GitHub Actions, no **computador**:

~~~sh
zstd -d -k rootfs.ext4.zst
file rootfs.ext4
~~~

Se o resultado de `file` indicar **ext4 raw**, converta para Android sparse antes de gravar:

~~~sh
img2simg rootfs.ext4 rootfs-sparse.img
fastboot flash userdata rootfs-sparse.img
~~~

Se `file` já indicar **Android sparse image**, não converta novamente: use `fastboot flash userdata rootfs.ext4`. Um fastboot compatível também pode aceitar o arquivo ext4 raw com `fastboot flash userdata rootfs.ext4`. `img2simg` e `simg2img` são utilitários do computador (pacote `android-sdk-libsparse-utils` em Debian/Ubuntu). Para converter sparse para raw: `simg2img rootfs-sparse.img rootfs-extraido.ext4`.

**Atenção:** gravar `userdata` substitui o conteúdo anterior. Valide partições, compatibilidade do boot e backup. O formato sparse **não** expande o filesystem.

### Fazer o ext4 ocupar o espaço disponível na partição

Depois de iniciar o Linux no **telefone**, como root:

~~~sh
findmnt -n -o SOURCE,FSTYPE /
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS
df -h /
~~~

**Somente se `/` for ext4 e a partição de root for identificada corretamente**, substitua o marcador pelo dispositivo que você confirmou:

~~~sh
resize2fs /dev/PARTICAO_ROOT_CONFIRMADA
df -h /
~~~

Sem tamanho explícito, `resize2fs` expande o ext4 até o limite da partição existente, quando o kernel aceita expansão online. Não execute `e2fsck` no filesystem montado. Se faltar `resize2fs` ou falhar online, use um ambiente de recuperação com filesystem desmontado e backup. Não reparticione o dispositivo somente para ajustar o ext4.
