# Moto G7 Play (channel) — Debian rootfs build

## Canonical rootfs identity

All current Channel rootfs builds use one identity only:

- file: `rootfs.ext4.zst`
- ext4 label: `rootfs`
- ext4 UUID: `89530000-6320-4000-8000-000000000001`

The mainline boot image has **no initramfs**. It mounts Android `userdata`
directly with `root=PARTUUID=76dbdefa-f243-cd22-5da5-9374e6ad318b`
`rootfstype=ext4 rootwait rw`. The ext4 UUID identifies the filesystem; it
is not the GPT PARTUUID used to locate the root partition.


The `debian` branch contains the separated Debian rootfs workflow.

Workflow: `.github/workflows/rootfs.yml`

Primary artifact: `channel-debian-rootfs`

## What the workflow builds

By default the run compiles a fresh kernel dependency so the rootfs contains matching modules. Enable `reuse_kernel` to reuse an existing kernel artifact.

That kernel build is an internal dependency of this workflow. The published artifact remains focused on the rootfs and does not include or generate an initramfs.

The workflow uses:

- `scripts/build-kernel.sh`;
- `scripts/build-rootfs.sh`;
- `config/channel-mainline.config`;
- the files under `rootfs/`.

## `channel-debian-rootfs`

Retained for 14 days.

It contains:

- `rootfs.ext4.zst` — final compressed ext4 rootfs image;
- `build-info.txt` — rootfs build metadata, including the selected SSH authentication mode;
- `SHA256SUMS.rootfs` — hashes for the generated rootfs outputs.

This workflow does not publish the kernel, DTB, lk2nd, or DTBO as its primary component outputs.

## Manual `Run workflow` fields

Use **Actions → Build rootfs → Run workflow** and keep the launcher branch set to `main`. The launcher checks out `debian` before building.

### `ssh_auth`

| Value | Build result |
| --- | --- |
| `generated-key` | Generates a new Ed25519 key for the run and publishes it in `channel-rootfs-ssh-test-key`. |
| `public-key-input` | Installs the public key supplied in `ssh_public_key`. No private key artifact is generated. |
| `public-key-secret` | Uses the `SSH_PUBLIC_KEY` repository secret. No private key artifact is generated. |
| `generated-password` | Generates a password for the run and publishes it in `channel-rootfs-ssh-password`. |
| `password-secret` | Uses the `SSH_PASSWORD` repository secret. The secret is not exported as an artifact. |
| `generated-key+generated-password` | Generates both a key and a password and publishes both temporary credential artifacts. |
| `public-key-input+password-secret` | Uses the `ssh_public_key` input together with `SSH_PASSWORD`. No credential is re-exported. |
| `public-key-secret+password-secret` | Uses `SSH_PUBLIC_KEY` and `SSH_PASSWORD`. No credential is re-exported. |
| `open-root-usb` | Enables direct root SSH only on the USB RNDIS address for bring-up/recovery. |

Default: `generated-key`.

### `ssh_public_key`

This input is used only by:

- `public-key-input`;
- `public-key-input+password-secret`.

Paste the complete public-key line into this field. Do not place a private key in this input.

## Optional repository secrets

- `SSH_PUBLIC_KEY` — required by the `public-key-secret` modes.
- `SSH_PASSWORD` — required by the `password-secret` modes.

If a selected mode requires a secret that is missing, the workflow fails instead of silently replacing it with another credential.

## Temporary credential artifacts

### `channel-rootfs-ssh-test-key`

Created only by modes that generate a key.

Contains:

- `channel_test_ed25519`;
- `channel_test_ed25519.pub`.

Retention: 1 day.

### `channel-rootfs-ssh-password`

Created only by modes that generate a password.

Contains:

- `channel_ssh_password.txt`.

Retention: 1 day.

## Push builds

A push to `debian` also runs the workflow.

For push-triggered builds the mode is automatic:

- if `SSH_PUBLIC_KEY` exists, that public key is used;
- otherwise a new Ed25519 key is generated and published in the temporary key artifact.

## Changes made in this branch

The rootfs build was separated from the integrated workflow so the rootfs can be rebuilt and downloaded on its own.

The workflow was then extended with:

- the `ssh_auth` selector;
- the `ssh_public_key` manual input;
- optional `SSH_PUBLIC_KEY` and `SSH_PASSWORD` secrets;
- optional generated-password output;
- key + password combinations;
- the `open-root-usb` recovery mode;
- temporary generated credential artifacts;
- authentication-mode recording in `build-info.txt`.


## Kernel consistency

The internal kernel dependency uses the validated Channel Wi-Fi path. The WCN3620 compatible is already in `SaaSD3v/linux`; the compiled DTB must report `qcom,wcn3620` for WCNSS IRIS, and required WCNSS kernel options are checked before rootfs generation.

## Network ownership

The Debian rootfs uses NetworkManager for `wlan0` Wi-Fi. The Channel RNDIS interface `usb0` is explicitly marked unmanaged by NetworkManager so `channel-usb-gadget` and dnsmasq retain exclusive ownership of the fixed `172.16.42.1/24` USB management network.

## GitHub Actions launchers

Kernel reuse is **off by default**: a normal rootfs run compiles the current
`SaaSD3v/linux:msm8953/latest`. Select `reuse_kernel` to use a published
kernel artifact; `kernel_run_id` is only accepted when reuse is enabled.

For `open-root-usb`, choose the dedicated `Build Debian rootfs (USB open root)` workflow exposed on the `main`
branch. It shows only a reuse checkbox, not SSH key/password fields.
The regular SSH workflow no longer lists `open-root-usb` as an option.
GitHub Actions cannot hide workflow_dispatch fields dynamically.
