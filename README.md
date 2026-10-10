# Moto G7 Play (channel) — Ubuntu Minimal mainline

This branch builds an Ubuntu Minimal userspace for the Motorola Moto G7 Play (`channel`, Qualcomm SDM632) while preserving the validated mainline kernel/lk2nd/DTBO flow from `main`.

---

## Userspace

The rootfs is based on the official **Ubuntu Base 26.04.1 LTS (Resolute) ARM64** tarball. The build verifies the pinned upstream SHA-256 before extracting it, then installs only the packages required for the headless device:

- systemd/udev/dbus;
- OpenSSH;
- iproute2 and ping;
- dnsmasq;
- BusyBox for the existing runtime DHCP helper;
- WCN36xx userspace tools (`iw`, `wpasupplicant`, `wireless-regdb`);
- systemd-timesyncd;
- small administration utilities.

No Ubuntu kernel or bootloader package is used. The rootfs receives the Channel mainline kernel modules produced by this repository.

The generated filesystem is:

`rootfs.ext4.zst`

with filesystem label:

`ubuntu-rootfs`

---

## USB SSH

The USB behavior intentionally matches the Debian branch:

- RNDIS gadget on `usb0`;
- device address `172.16.42.1/24`;
- dnsmasq gives the Windows/Linux host `172.16.42.2` through `172.16.42.20`;
- sshd listens only on `172.16.42.1`.

The expected host behavior is automatic DHCP; a manual Windows IPv4 address should not be required.

---

## Wi-Fi

`channel-wifi-firmware.service` keeps the validated Channel-specific WCNSS
firmware path: it mounts the stock modem/vendor partitions read-only, prepares
the firmware/NV files, starts the remote processor, and loads `wcn36xx`.

NetworkManager then owns `wlan0`, Wi-Fi association, DHCP, routes, and DNS.
The firmware service is ordered before NetworkManager.

Configure Wi-Fi with:

```sh
nmcli dev wifi list
nmcli dev wifi connect "<network-name>" password "<password>"
```

NetworkManager persists the connection profile for later boots. The old
Channel-specific supplicant, DHCP-client service, config watcher, and udhcpc
hook are not used.

---

## Rootfs build

Use `.github/workflows/rootfs.yml` to build the Ubuntu userspace with matching
kernel modules. It reuses the kernel checkpoint when possible and otherwise
builds the matching kernel as an internal dependency. This generates a rootfs
image, not a new boot image or initramfs.

The obsolete integrated `build.yml` (which expected a missing initramfs
builder) was removed from this branch. The validated standalone kernel build
publishes the direct-root `boot-channel.img` using
`root=PARTUUID=76dbdefa-f243-cd22-5da5-9374e6ad318b`.

SSH management uses one fixed mode, `ssh`, without workflow authentication
inputs or downloadable user credentials. For a host connected over USB, the
intended connection is `ssh root@172.16.42.1`. Test SSH and network isolation
on the device before relying on it.

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
