# GitHub automation

This directory contains repository automation used by GitHub Actions.

The actual workflow definitions live in `.github/workflows/`. Which workflow files are present depends on the branch:

- `main` exposes the integrated build plus the manual launchers for the separated builds.
- Each component branch keeps only its component workflow.

No device build output is stored in this directory.
