# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A [Concourse CI](https://concourse.ci/) resource that uses rsync over SSH to persist and retrieve build artifacts on shared storage. It implements the three Concourse resource behaviors: `check`, `in`, and `out`.

## Building and running

The resource runs inside Docker (Alpine Linux). Build and test via Docker:

```sh
docker build -t concourse-rsync-resource .
```

Scripts are plain bash — no compile step. To test locally without Docker, source the env and pipe JSON:

```sh
source test/test_env.sh          # sets BUILD_ID, BUILD_PIPELINE_NAME, etc.
cat test/test.json | assets/check
cat test/test.json | assets/in /tmp/dest
cat test/test.json | assets/out /tmp/src
```

## Architecture

All logic lives in three executable bash scripts under `assets/`, which Concourse copies to `/opt/resource/` inside the container:

- **`assets/check`** — Lists available artifact versions from the remote server. Connects via SSH, lists `base_dir` contents. Returns a JSON array of `{"ref": "<dir>"}` objects. With `disable_version_path: false` (default), each subdirectory is a version; with `true`, the `base_dir` itself is the single version.
- **`assets/in`** — Downloads a specific version. Takes destination dir as `$1`. rsync-pulls from `server:base_dir/<version>/` into the destination.
- **`assets/out`** — Uploads artifacts to one or more servers. Takes source dir as `$1`. Generates a version string as `md5(BUILD_PIPELINE_NAME-BUILD_ID)`, creates `base_dir/<md5>/` on each server via SSH, then rsync-pushes `sync_dir` contents there.
- **`assets/askpass.sh`** — SSH helper that rejects passphrase-protected keys (passphrases are unsupported).

### Key design details

- JSON config is read from stdin into `/tmp/input`; scripts use `jq` to extract fields.
- `servers` (list) takes precedence over `server` (single). `check`/`in` use only the first server; `out` pushes to all servers.
- `disable_version_path` is read via `jq -re` exit code (0 = true, 1 = false/absent) — the inverted exit code pattern is used throughout.
- SSH keys are written to `~/.ssh/server_key` with `StrictHostKeyChecking no`.
- `rsync_opts` param on `out` overrides the default `-Pav`.
- Debug output goes to stderr; only the final JSON version string goes to stdout.

## Concourse resource protocol

- **`check` stdout**: JSON array of version objects, newest last — `[{"ref": "..."}]`
- **`in` stdout**: JSON with `version` key — `{"version": {"ref": "..."}}`
- **`out` stdout**: JSON with `version` key — `{"version": {"ref": "<md5>"}}`
- All scripts receive the full source/params config as JSON on stdin.
