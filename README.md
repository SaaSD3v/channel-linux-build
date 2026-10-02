# Moto G7 Play (channel) — lk2nd

Esta branch gera somente o lk2nd usado pelo Channel.

O workflow é `.github/workflows/lk2nd.yml` e o artifact é `channel-lk2nd-msm8953`.

## Fonte e target

A run usa:

- repositório: `https://github.com/msm8916-mainline/lk2nd.git`;
- referência: `23.1`;
- target: `lk2nd-msm8953`.

Antes do upload, o workflow verifica no binário as referências ao Moto G7 Play (Channel) e ao DTB `sdm632-motorola-channel`.

## Artifact `channel-lk2nd-msm8953`

Mantido por 14 dias. Contém:

- `lk2nd-msm8953.img` — imagem compilada;
- `lk2nd-commit.txt` — commit exato da fonte usada;
- `SHA256SUMS.lk2nd` — hash da imagem produzida.

O arquivo de commit acompanha o artifact para identificar exatamente a revisão usada no build.

## Disparo manual

O workflow também está exposto na `main`.

Use **Actions → Build lk2nd MSM8953 → Run workflow** com a branch `main`. O launcher faz checkout da branch `lk2nd`.

## O que foi alterado nesta branch

O lk2nd foi separado do build completo para poder ser recompilado e baixado sozinho.

Durante a separação, uma primeira run falhou porque o ambiente individual não instalava `dtc`. O workflow foi corrigido restaurando `device-tree-compiler` e `libfdt-dev`, dependências que já estavam presentes no build completo conhecido-bom. A run seguinte passou.

Este workflow não gera kernel, rootfs ou DTBO.
