# lk2nd workflow

This directory contains `lk2nd.yml`, the separated lk2nd build.

It builds the `lk2nd-msm8953` target from lk2nd 23.1, validates the Channel strings in the output, records the source commit and SHA-256 hash, and uploads the `channel-lk2nd-msm8953` artifact.

Pushes to `lk2nd` run this workflow automatically. The copy exposed on `main` is used for manual dispatch.
