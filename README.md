# Moto G7 Play (channel) — kernel mainline 7.1 build

This branch contains the separated kernel workflow.

Workflow: `.github/workflows/kernel-mainline-7.1.yml`

Primary artifact: `channel-kernel-mainline-7.1`

## Source and build

The workflow clones:

`https://gitlab.com/moto8953-revived/channel/Mainline/channel-linux.git`

using the `channel` branch, then builds the Channel kernel with the project configuration and helper script.

The kernel, DTB, modules, configuration, and symbol map are produced together so the artifact represents one consistent build.

### Channel Wi-Fi device-tree fix

`scripts/build-kernel.sh` applies `wcn3620-fix.patch` to the cloned kernel
before configuring and compiling it. The patch changes `&wcnss_iris` in
`arch/arm64/boot/dts/qcom/sdm632-motorola-channel.dts` from
`qcom,wcn3660b` to `qcom,wcn3620`, selecting the 19.2 MHz IRIS XO
configuration required by the tested device. It also corrects the adjacent
comment. This resolved `qcom-wcnss-pil: start timed out (-110)`; validation
on the device included WCNSS reaching `running`, scanning, WPA2 association,
and successful IP traffic over `wlan0`.

The helper accepts an already-applied patch and stops on a conflicting
kernel tree. The workflow verifies the compatible in the compiled DTB
and records the patch checksum and source diff in `source-report.txt`.

The project config also pins the validated WCNSS kernel path explicitly
(WCN36XX, WCNSS PIL/control, Qualcomm SMD/SMEM/SMP2P/SMSM, cfg80211 and
mac80211), and the shared helper verifies the expected built-in/module
states after `olddefconfig`.

To apply the same fix manually, run from the kernel source directory:

```sh
git apply --check /path/to/channel-pmos-build/wcn3620-fix.patch
git apply /path/to/channel-pmos-build/wcn3620-fix.patch
```

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
- `wcn3620-fix.patch` — Channel Wi-Fi device-tree fix used for this build;
- `SHA256SUMS` — hashes for the main generated outputs.

## Manual run

Use **Actions → Build kernel mainline 7.1 → Run workflow** on `main`.

The launcher checks out `kernel-mainline-7.1` before building.

## Changes made in this branch

This branch was created so the kernel can be rebuilt and downloaded without also building rootfs, lk2nd, or DTBO.

The workflow publishes only kernel-related outputs.
