# Channel Linux Build — Moto G7 Play (channel)

Builds do **Motorola Moto G7 Play (SDM632)**: kernel mainline ARM64, rootfs e componentes de boot. Este documento descreve **somente este repositório** e suas branches; Sanders e builds experimentais têm outros guias.

## Builds e branches

| Branch | Função | Workflow |
| --- | --- | --- |
| `main` | Integrado: kernel + Debian + boot + DTBO + lk2nd | `build.yml` (nome exibido atualmente: **For test only**) |
| `debian` | Rootfs Debian Trixie e módulos | `rootfs.yml` |
| `ubuntu` | Rootfs Ubuntu 26.04.1 e módulos | `rootfs.yml` |
| `alpine` | Rootfs Alpine 3.24, OpenRC e módulos | `rootfs.yml` |
| `kernel-mainline-7.1` | Kernel, DTB, módulos e boot direto | `kernel-mainline-7.1.yml` |
| `dtbo` | DTBO Channel | `dtbo.yml` |
| `lk2nd` | lk2nd MSM8953 | `lk2nd.yml` |

Os lançadores de componentes aparecem na `main`. Para executar: **Actions → workflow desejado → Run workflow → selecione a branch adequada**. Nos rootfs, `reuse_kernel` e `kernel_run_id` só controlam reutilização de um kernel pronto; sem artefato utilizável o workflow pode compilar o kernel como dependência. Não existe seletor de autenticação SSH.

O `build.yml` integrado também roda em pushes para `main`. Para compilar somente um rootfs, use o `rootfs.yml` da branch da distribuição.

## Arquivos e identidade do Channel

- Kernel: [SaaSD3v/linux](https://github.com/SaaSD3v/linux), `msm8953/latest`; DTB `sdm632-motorola-channel.dtb` com `qcom,wcn3620`.
- Configuração: `config/channel-mainline.config`; helpers: `scripts/build-kernel.sh`, `scripts/build-rootfs.sh` e, na `main`, `scripts/build-bootimg.sh`.
- Kernel separado: artefato `channel-kernel-mainline-7.1`, com `boot-channel.img`, DTB, módulos, `System.map` e metadados.
- Integrado: artefato `channel-mainline-debian` com `rootfs.ext4.zst`, `boot-channel.img`, `lk2nd-msm8953.img`, `dtbo-motorola-channel.img` e checksums.
- Rootfs separado: artefato `rootfs` com `rootfs.ext4.zst`, `build-info.txt` e `SHA256SUMS.rootfs`.

O boot é **direto, sem initramfs**, usando a partição Android `userdata`:

```text
root=PARTUUID=76dbdefa-f243-cd22-5da5-9374e6ad318b rootfstype=ext4 rootwait rw
```

Os rootfs desse repositório usam label ext4 `rootfs` e UUID de filesystem `89530000-6320-4000-8000-000000000001`. **PARTUUID da partição GPT não é UUID do filesystem ext4.** Verifique a partição do aparelho antes de gravar imagens; o build não reparticiona o telefone.

Para descompactar um artefato no computador, após baixá-lo do Actions:

```sh
zstd -d -k rootfs.ext4.zst
```

Confirme também o `build-info.txt`, as versões de kernel/módulos e os checksums publicados.

## SSH de desenvolvimento via USB RNDIS

O telefone usa `172.16.42.1/24`; o DHCP USB oferece endereços `172.16.42.2` a `172.16.42.20` ao host. No computador conectado por USB:

```sh
ssh root@172.16.42.1
```

`ssh_auth=ssh` é fixo: não há inputs de chave/senha nem credenciais de usuário geradas pelo build. Esse modo concede acesso root a quem conectá-lo; evite computadores não confiáveis. `ListenAddress 172.16.42.1` **não garante**, sozinho, bloqueio de conexões provenientes de outras interfaces: valide no hardware.

## Wi-Fi e Internet com NetworkManager

Debian, Ubuntu e Alpine do **channel-linux-build** incluem NetworkManager, firmware WCNSS e suporte à interface `wlan0`. O `usb0` deve permanecer fora do controle do NetworkManager para preservar o gadget USB.

Execute no **shell do telefone**, por SSH:

```sh
# Verificar interfaces e o gerenciador
ip -br link
nmcli general status
nmcli device status

# Escanear redes próximas
nmcli radio wifi on
nmcli device wifi rescan ifname wlan0
nmcli -f IN-USE,SSID,SIGNAL,SECURITY device wifi list ifname wlan0

# Conectar: solicita a senha sem escrevê-la no histórico
nmcli --ask device wifi connect "NOME_DA_REDE" ifname wlan0

# Conferir conexão e acesso à Internet
nmcli connection show --active
ip -4 address show dev wlan0
ip route
getent hosts debian.org
ping -c 3 1.1.1.1
```

Alternativa menos privada: `nmcli device wifi connect "NOME_DA_REDE" password "SENHA" ifname wlan0`, que pode deixar a senha no histórico. Para um perfil salvo: `nmcli connection up "NOME_DA_CONEXAO"`.

Se `wlan0` não aparecer, confira firmware/módulo `wcn36xx` e o serviço de rede:

```sh
# Debian / Ubuntu (systemd)
systemctl status NetworkManager --no-pager
journalctl -b -u NetworkManager --no-pager -n 80

# Alpine (OpenRC)
rc-service networkmanager status
```

O kernel e seus módulos devem corresponder à **mesma compilação**. Um workflow concluído não substitui a validação de boot, Wi-Fi e USB no celular.

## Data e hora — ajuste manual temporário

Os scripts deste repositório não configuram um serviço NTP personalizado. `TZ` altera apenas a **apresentação do fuso horário**, não conserta um relógio com data errada. Isso pode afetar TLS/HTTPS, gerenciadores de pacotes e logs.

No **telefone**, como root, utilize a **data e hora UTC atuais**. O valor abaixo é **ilustrativo**: substitua-o antes de executar.

```sh
date -u
date -u -s "2026-10-10 12:00:00"   # EXEMPLO; insira a data/hora UTC real
date -u
date
```

Sem sincronização automática, o valor pode voltar a ficar incorreto após reiniciar, sobretudo se o RTC estiver errado. Para exibir outro fuso sem alterar o relógio: `TZ=America/Porto_Velho date` (se os dados do fuso estiverem instalados).
