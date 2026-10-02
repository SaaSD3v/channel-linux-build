# DTBO workflow

This directory contains `dtbo.yml`, the separated Channel DTBO build.

It installs the DTBO build dependencies, builds `dtbo-motorola-channel.img`, records the source commit and SHA-256 hash, and uploads the `channel-dtbo` artifact.

Pushes to `dtbo` run this workflow automatically. The copy exposed on `main` is used for manual dispatch.
