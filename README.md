# Moto G7 Play (channel) — DTBO

Esta branch gera somente o DTBO mínimo usado pelo fluxo do Channel.

O workflow é `.github/workflows/dtbo.yml` e o artifact é `channel-dtbo`.

## Fonte

A run clona:

`https://github.com/barni2000/dtbo-lk2nd.git`

e gera o target `build/dtbo-motorola-channel.img`.

## Artifact `channel-dtbo`

Mantido por 14 dias. Contém:

- `dtbo-motorola-channel.img` — imagem DTBO gerada;
- `dtbo-lk2nd-commit.txt` — commit exato da fonte usada;
- `SHA256SUMS.dtbo` — hash da imagem produzida.

O commit da fonte é incluído para permitir identificar exatamente de qual revisão veio o arquivo baixado.

## Disparo manual

O workflow também está exposto na `main`.

Use **Actions → Build channel DTBO → Run workflow** com a branch `main`. O launcher faz checkout da branch `dtbo`.

## O que foi alterado nesta branch

O DTBO foi separado do build completo para poder ser recompilado e baixado sozinho.

Este workflow não gera kernel, rootfs ou lk2nd.
