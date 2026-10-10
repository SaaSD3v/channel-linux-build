# Moto G7 Play (channel) — DTBO build

This branch contains the separated Channel DTBO workflow.

Workflow: `.github/workflows/dtbo.yml`

Primary artifact: `channel-dtbo`

---

## Source and target

The workflow clones:

`https://github.com/barni2000/dtbo-lk2nd.git`

and builds:

`build/dtbo-motorola-channel.img`

---

## `channel-dtbo`

Retained for 14 days.

It contains:

- `dtbo-motorola-channel.img` — generated Channel DTBO image;
- `dtbo-lk2nd-commit.txt` — exact source commit used for the build;
- `SHA256SUMS.dtbo` — hash of the generated image.

The commit file is included so a downloaded DTBO can be tied back to the exact source revision used by the run.

---

## Manual run

Use **Actions → Build channel DTBO → Run workflow** on `main`.

The launcher checks out `dtbo` before building.

---

## Changes made in this branch

The DTBO build was separated from the integrated build so it can be rebuilt and downloaded on its own.

This workflow does not publish kernel, rootfs, or lk2nd outputs.
