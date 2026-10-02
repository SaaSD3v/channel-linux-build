# Moto G7 Play (channel) — kernel mainline 7.1 build

This branch contains the separated kernel workflow.

Workflow: `.github/workflows/kernel-mainline-7.1.yml`

Primary artifact: `channel-kernel-mainline-7.1`

## Source and build

The workflow clones:

`https://gitlab.com/moto8953-revived/channel/Mainline/channel-linux.git`

using the `channel` branch, then builds the Channel kernel with the project configuration and helper script.

The kernel, DTB, modules, configuration, and symbol map are produced together so the artifact represents one consistent build.

## `channel-kernel-mainline-7.1`

Retained for 14 days.

It contains:

- `Image.gz` — compressed ARM64 kernel image;
- `Image.gz-dtb` — kernel image concatenated with the Channel DTB;
- `sdm632-motorola-channel.dtb` — compiled Channel DTB;
- `kernel.config-*` — final kernel configuration produced by the helper build;
- `kernel-release.txt` — exact kernel release;
- `kernel-git-revision.txt` — exact kernel source commit;
- `kernel-modules-*.tar.zst` — modules matching that release;
- `System.map` — kernel symbol map;
- `source-report.txt` — source URL/ref/commit details captured by the workflow;
- `SHA256SUMS` — hashes for the main generated outputs.

## Manual run

Use **Actions → Build kernel mainline 7.1 → Run workflow** on `main`.

The launcher checks out `kernel-mainline-7.1` before building.

## Changes made in this branch

This branch was created so the kernel can be rebuilt and downloaded without also building rootfs, lk2nd, or DTBO.

The workflow publishes only kernel-related outputs.
