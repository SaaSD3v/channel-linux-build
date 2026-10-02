# Moto G7 Play (channel) — kernel mainline 7.1

Esta branch mantém o build separado do kernel usado no projeto.

O workflow é `.github/workflows/kernel-mainline-7.1.yml` e o artifact produzido é `channel-kernel-mainline-7.1`.

## Fonte e build

A run clona uma cópia nova de:

`https://gitlab.com/moto8953-revived/channel/Mainline/channel-linux.git`

usando a branch `channel`.

A configuração é feita pelos arquivos já existentes no projeto, incluindo `config/channel-mainline.config` e `scripts/build-kernel.sh`.

O build produz kernel, DTB e módulos compatíveis entre si na mesma run.

## Artifact `channel-kernel-mainline-7.1`

Mantido por 14 dias. Contém:

- `Image.gz` — kernel ARM64 comprimido;
- `Image.gz-dtb` — kernel concatenado ao DTB do Channel;
- `sdm632-motorola-channel.dtb` — DTB compilado do aparelho;
- `kernel.config-*` — configuração final usada no kernel;
- `kernel-release.txt` — release exato produzido pela compilação;
- `kernel-git-revision.txt` — commit do tree de kernel usado;
- `kernel-modules-*.tar.zst` — módulos instaláveis correspondentes ao mesmo release;
- `System.map` — mapa de símbolos dessa build;
- `source-report.txt` — origem e commit da fonte;
- `SHA256SUMS` — hashes dos principais arquivos gerados.

## Disparo manual

O workflow também está exposto na `main` para aparecer no GitHub Actions.

Use **Actions → Build kernel mainline 7.1 → Run workflow** com a branch `main`. O launcher faz checkout de `kernel-mainline-7.1` antes do build.

## O que foi alterado nesta branch

A branch foi separada para que o kernel possa ser recompilado e baixado sem executar rootfs, lk2nd ou DTBO.

Nenhum artifact de rootfs, lk2nd ou DTBO é publicado por este workflow.
