# Moto G7 Play (channel) — Debian ARM64 rootfs

This branch builds Debian Trixie userspace and matching mainline kernel
modules; it does not build an initramfs or a new boot image.

---

## Filesystem and boot

- Rootfs artifact: `rootfs.ext4.zst`
- Ext4 label: `rootfs`
- Ext4 UUID: `89530000-6320-4000-8000-000000000001`
- Boot locator (separate from the ext4 UUID):
  `root=PARTUUID=76dbdefa-f243-cd22-5da5-9374e6ad318b`

The validated kernel component provides `boot-channel.img` with direct-root
mounting; it has no initramfs. This branch generates only rootfs artifacts.

---

## GitHub Actions

`.github/workflows/rootfs.yml` supports manual dispatch and also runs on
pushes to `debian`. It reuses a matching kernel artifact when available, or
builds a kernel dependency to install the correct modules. Its outputs include
`rootfs.ext4.zst`, `build-info.txt` and `SHA256SUMS.rootfs`.

The only user-facing manual options concern kernel artifact reuse. There are
no SSH authentication inputs, Secrets, generated user keys or password files.

---

## USB SSH

SSH management is fixed as `ssh`, listening on `172.16.42.1` over the
Channel RNDIS gadget. The intended connection is:

```sh
ssh root@172.16.42.1
```

USB SSH access without user credentials is intended for device bring-up.
Confirm login and USB-only network isolation with the real phone. A matching
Unix root password is not left empty for local/serial login.

---

## Network ownership

NetworkManager handles Wi-Fi (`wlan0`), while `usb0` is unmanaged so the
USB gadget and dnsmasq retain control of `172.16.42.1/24`. Kernel/WCNSS
configuration and the validated `qcom,wcn3620` device-tree path remain
unchanged.

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
