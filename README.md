# Moto G7 Play (channel) — Debian mainline bring-up

Repositório de build para o Motorola Moto G7 Play (codename `channel`, SDM632).

## Objetivo

A pipeline gera e valida artefatos separados para um bring-up seguro:

- `lk2nd-msm8953.img` a partir do lk2nd upstream atual;
- `dtbo-motorola-channel.img` mínimo exigido pelo lk2nd em SDM632;
- kernel mainline do tree `moto8953-revived/channel/Mainline/channel-linux`;
- `boot-channel.img` Android boot image para o lk2nd;
- Debian 13 (trixie) arm64 em `debian-channel-rootfs.ext4.zst`;
- SSH headless por USB RNDIS em `172.16.42.1`.

## Segurança do SSH

A build usa somente autenticação por chave. Senha e keyboard-interactive ficam desativados.

Se o secret GitHub Actions `SSH_PUBLIC_KEY` contiver sua chave pública OpenSSH, ela será instalada em `/root/.ssh/authorized_keys`.

Se o secret estiver ausente, a CI gera uma chave ED25519 de bring-up e publica a chave privada em um artefato separado chamado `channel-ssh-test-key`. Essa chave é somente para teste inicial e deve ser substituída por uma chave pessoal.

O sshd escuta apenas no endereço USB `172.16.42.1`.

## USB

O gadget usa uma única função RNDIS via configfs, com Microsoft OS descriptors. Isso evita a configuração dual RNDIS/ECM que costuma exigir tratamento extra no Windows. O host recebe endereço por DHCP no range `172.16.42.2-20`.

No Windows 10 (OpenSSH Client instalado):

```powershell
ssh -i .\channel_test_ed25519 root@172.16.42.1
```

No Linux:

```sh
chmod 600 channel_test_ed25519
ssh -i ./channel_test_ed25519 root@172.16.42.1
```

## Estratégia de armazenamento

A primeira build não reparticiona o eMMC. O rootfs é uma imagem ext4 com label `debian-rootfs`, pensada para ser escrita em um microSD durante o bring-up. O kernel usa `root=LABEL=debian-rootfs rootwait`.

## Bootloader

O fork antigo `00p513-dev/lk2nd` é mantido apenas como referência histórica. Ele não contém o suporte atual do Moto G7 Play. A build usa o lk2nd upstream `msm8916-mainline/lk2nd` tag `23.1`, cujo target correto é `lk2nd-msm8953`.

**Não flashe nada antes de conferir os artefatos e os logs da CI.** Para o primeiro teste prefira `fastboot boot` quando o bootloader aceitar. O DTBO mínimo é requisito do lk2nd para este aparelho e deve ser tratado com cuidado porque grava a partição `dtbo`.
