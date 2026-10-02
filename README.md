# Moto G7 Play (channel) — lk2nd build

This branch contains the separated lk2nd workflow.

Workflow: `.github/workflows/lk2nd.yml`

Primary artifact: `channel-lk2nd-msm8953`

## Source and target

The workflow uses:

- repository: `https://github.com/msm8916-mainline/lk2nd.git`;
- reference: `23.1`;
- target: `lk2nd-msm8953`.

Before upload, the workflow checks the built image for the Channel device strings used by this project.

## `channel-lk2nd-msm8953`

Retained for 14 days.

It contains:

- `lk2nd-msm8953.img` — compiled lk2nd image;
- `lk2nd-commit.txt` — exact lk2nd source commit used;
- `SHA256SUMS.lk2nd` — hash of the generated image.

The commit file is included so a downloaded image can be tied back to the exact source revision used by the run.

## Manual run

Use **Actions → Build lk2nd MSM8953 → Run workflow** on `main`.

The launcher checks out `lk2nd` before building.

## Changes made in this branch

The lk2nd build was separated from the integrated build so it can be rebuilt and downloaded independently.

During the first separated run, the environment was missing `dtc`. The workflow was corrected by restoring `device-tree-compiler` and `libfdt-dev`, matching dependencies already available in the known integrated build. The next separated lk2nd run completed successfully.

This workflow does not publish kernel, rootfs, or DTBO outputs.
