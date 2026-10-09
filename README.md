# Moto G7 Play (channel) — mainline kernel component

This branch builds the **kernel-side** artifacts independently of any userspace
rootfs. Workflow: `.github/workflows/kernel-mainline-7.1.yml`.

## Actual kernel source

- GitHub: `https://github.com/SaaSD3v/linux.git`
- Ref: `msm8953/latest`
- Device: Motorola Moto G7 Play (`channel`, SDM632)
- Device tree: `arch/arm64/boot/dts/qcom/sdm632-motorola-channel.dts`
- Compiler: AArch64 cross-GCC, as used by `scripts/build-kernel.sh`

The kernel tree already contains the validated `qcom,wcn3620` WCNSS IRIS
compatible. No external `wcn3620-fix.patch` is applied in the current workflow.
The compiled DTB is checked for this compatible. WCN36xx, WCNSS PIL/control,
Qualcomm messaging and USB/RNDIS kernel config values are validated after
`olddefconfig`.

## Boot model

The generated `boot-channel.img` includes the compressed ARM64 kernel and
Channel DTB. **It has no ramdisk or initramfs.** The cmdline includes:

```text
root=PARTUUID=76dbdefa-f243-cd22-5da5-9374e6ad318b rootfstype=ext4 rootwait rw
```

This PARTUUID identifies the GPT partition `userdata`. It is **not** the ext4
filesystem UUID `89530000-6320-4000-8000-000000000001`, which the rootfs
builders use to identify the filesystem inside that partition.

## Artifacts

A successful workflow publishes:

- `boot-channel-img`: just the boot image.
- `channel-kernel-mainline-7.1`: `boot-channel.img`,
  `kernel-cmdline.txt`, `Image.gz`, `Image.gz-dtb`,
  `sdm632-motorola-channel.dtb`, `kernel.config-*`,
  `kernel-release.txt`, `kernel-git-revision.txt`,
  `kernel-modules-*.tar.zst`, `System.map`, `source-report.txt`,
  and `SHA256SUMS`.

Each artifact is retained for 14 days. The kernel modules archive must match
the exact kernel release used by a particular rootfs.

## Usage

The manual workflow is exposed on `main`; it builds the kernel from GitHub
using `msm8953/latest`. This component build has no SSH credentials or
distribution-specific rootfs. Debian/Ubuntu/Alpine rootfs workflows use their
own optional `reuse_kernel` flag, which is **off by default**. Only when the
flag is selected can they reuse a saved kernel artifact from this workflow.
