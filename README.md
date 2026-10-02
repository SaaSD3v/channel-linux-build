# Moto G7 Play (channel) — builds do projeto

Este repositório mantém o build completo na branch `main` e builds separados por componente nas branches `rootfs`, `kernel-mainline-7.1`, `dtbo` e `lk2nd`.

## Build completo da `main`

O workflow `.github/workflows/build.yml` continua sendo o fluxo integrado que já foi usado para gerar o conjunto completo.

Ele executa, na mesma run:

- kernel mainline, DTB e módulos;
- lk2nd para MSM8953/SDM632;
- DTBO mínimo do Channel;
- Debian rootfs e initramfs;
- `boot-channel.img`;
- validações e hashes finais.

### Artifacts do build completo

O artifact principal é `channel-mainline-debian`. Ele reúne:

- `boot-channel.img` — imagem de boot já empacotada com kernel + DTB + initramfs;
- `lk2nd-msm8953.img` — lk2nd compilado para o target usado pelo Channel;
- `dtbo-motorola-channel.img` — DTBO mínimo usado com lk2nd;
- `Image.gz` — kernel ARM64 comprimido;
- `Image.gz-dtb` — kernel concatenado ao DTB do Channel;
- `*.dtb` — DTB compilado do aparelho;
- `initrd.img-*` — initramfs correspondente ao kernel da run;
- `debian-channel-rootfs.ext4.zst` — imagem ext4 do Debian comprimida;
- `build-info.txt` — informações da geração do rootfs;
- `source-report.txt` — revisão/commit e dados da fonte usada;
- `lk2nd-commit.txt` e `dtbo-lk2nd-commit.txt` — commits exatos usados nesses componentes;
- `kernel.config`, `System.map` e `kernel-release.txt` — arquivos de referência do kernel;
- `kernel-modules-*.tar.zst` — módulos do mesmo kernel;
- `SHA256SUMS*` — hashes produzidos pela run.

Esse artifact é mantido por 14 dias.

Se o build completo não receber o secret `SSH_PUBLIC_KEY`, ele também pode publicar `channel-ssh-test-key` com a chave gerada para aquele rootfs. Esse artifact fica disponível por 1 dia.

## Builds separados

Os workflows separados existem para gerar apenas um grupo de artifacts por vez:

| Branch | Workflow | Artifact principal |
| --- | --- | --- |
| `rootfs` | `Build Debian rootfs` | `channel-debian-rootfs` |
| `kernel-mainline-7.1` | `Build kernel mainline 7.1` | `channel-kernel-mainline-7.1` |
| `dtbo` | `Build channel DTBO` | `channel-dtbo` |
| `lk2nd` | `Build lk2nd MSM8953` | `channel-lk2nd-msm8953` |

Os quatro YAMLs também existem na `main` para aparecerem no GitHub Actions e permitirem disparo manual. Quando disparados pela `main`, cada launcher faz checkout da branch correspondente antes de compilar.

## Mudanças recentes na organização

O projeto foi separado em builds individuais sem remover o build completo da `main`.

Também foram adicionadas opções de autenticação somente ao workflow separado de `rootfs`. Essas opções não alteram o comportamento do `build.yml` monolítico da `main`.

Para detalhes de cada artifact e dos campos de execução manual, consulte o `README.md` da branch correspondente.
