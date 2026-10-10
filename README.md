# Moto G7 Play (channel) — kernel mainline 7.1 build

This branch contains the separated kernel workflow.

Workflow: `.github/workflows/kernel-mainline-7.1.yml`

Primary artifact: `channel-kernel-mainline-7.1`

## Source and build

The workflow clones `https://github.com/SaaSD3v/linux.git` at
`msm8953/latest` and builds the kernel with the project config and helper.

The kernel, DTB, modules, configuration, symbol map, and rootfs-independent `boot-channel.img` are produced together so the artifact represents one consistent kernel-side build.

### Channel Wi-Fi device tree

The `qcom,wcn3620` WCNSS IRIS compatible is already present in the pinned
`SaaSD3v/linux:msm8953/latest` source. The workflow checks that this value
survives DTB compilation; it does not apply a local `wcn3620-fix.patch`.

The config fragment retains the Channel WCN36XX/WCNSS kernel requirements,
and `scripts/build-kernel.sh` verifies expected built-in/module states.
Source commit and build information are recorded with the artifacts.

## `channel-kernel-mainline-7.1`

Retained for 14 days.

It contains:

- `boot-channel.img` — rootfs-independent Android boot image with kernel + Channel DTB and no initramfs;
- `kernel-cmdline.txt` — boot command line using the fixed Channel root-partition PARTUUID;
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

This branch builds the kernel side independently from every distro. It does not build a rootfs, initramfs, lk2nd, DTBO, SSH configuration, or userspace credentials.

The generated `boot-channel.img` mounts `PARTUUID=76dbdefa-f243-cd22-5da5-9374e6ad318b` directly and therefore can be reused with Debian, Alpine, or Ubuntu on that root partition as long as the rootfs contains the matching kernel modules.
