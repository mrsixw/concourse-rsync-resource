#!/usr/bin/env bats

load helpers

SCRIPT="$BATS_TEST_DIRNAME/../assets/out"

setup() {
  setup_mocks
  SRC="$BATS_TEST_TMPDIR/src"
  mkdir -p "$SRC/myartifacts"
  export BUILD_PIPELINE_NAME="mypipeline"
  export BUILD_ID="42"
}

# Scripts print debug lines to stderr; bats mixes stderr+stdout into $output.
# The JSON payload is always the last line, so we extract it with ${lines[-1]}.

# ---------------------------------------------------------------------------
# Output JSON
# ---------------------------------------------------------------------------

@test "out: outputs md5 hash of pipeline-buildid as version ref" {
  run bash "$SCRIPT" "$SRC" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "params": {"sync_dir": "myartifacts"}
  }'
  [ "$status" -eq 0 ]
  ref=$(echo "${lines[-1]}" | jq -r '.version.ref')
  # mock md5sum always returns aabbcc112233aabbcc112233aabbcc11
  [ "$ref" = "aabbcc112233aabbcc112233aabbcc11" ]
}

# ---------------------------------------------------------------------------
# SSH mkdir
# ---------------------------------------------------------------------------

@test "out: creates destination directory via ssh" {
  run bash "$SCRIPT" "$SRC" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "params": {"sync_dir": "myartifacts"}
  }'
  [ "$status" -eq 0 ]
  grep 'mkdir' "$MOCK_SSH_CALLS_FILE"
}

@test "out: mkdir path includes md5 hash when disable_version_path false" {
  run bash "$SCRIPT" "$SRC" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "params": {"sync_dir": "myartifacts"}
  }'
  grep '/sync/dir/aabbcc112233aabbcc112233aabbcc11' "$MOCK_SSH_CALLS_FILE"
}

@test "out: mkdir path is just base_dir when disable_version_path true" {
  run bash "$SCRIPT" "$SRC" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy",
      "disable_version_path": true
    },
    "params": {"sync_dir": "myartifacts"}
  }'
  [ "$status" -eq 0 ]
  grep 'mkdir.*\/sync\/dir' "$MOCK_SSH_CALLS_FILE"
  ! grep 'mkdir.*aabbcc' "$MOCK_SSH_CALLS_FILE"
}

# ---------------------------------------------------------------------------
# rsync invocation
# ---------------------------------------------------------------------------

@test "out: rsync is called with src sync_dir and remote dest" {
  run bash "$SCRIPT" "$SRC" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "params": {"sync_dir": "myartifacts"}
  }'
  [ "$status" -eq 0 ]
  grep 'myartifacts' "$MOCK_RSYNC_CALLS_FILE"
}

@test "out: rsync uses -Pav by default" {
  run bash "$SCRIPT" "$SRC" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "params": {"sync_dir": "myartifacts"}
  }'
  grep -- '-Pav' "$MOCK_RSYNC_CALLS_FILE"
}

@test "out: rsync uses custom rsync_opts when provided" {
  run bash "$SCRIPT" "$SRC" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "params": {
      "sync_dir": "myartifacts",
      "rsync_opts": ["--archive", "--compress"]
    }
  }'
  grep -- '--archive --compress' "$MOCK_RSYNC_CALLS_FILE"
  ! grep -- '-Pav' "$MOCK_RSYNC_CALLS_FILE"
}

# ---------------------------------------------------------------------------
# Multiple servers
# ---------------------------------------------------------------------------

@test "out: pushes to all servers when servers list is provided" {
  run bash "$SCRIPT" "$SRC" <<< '{
    "source": {
      "servers": ["host1", "host2"],
      "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "params": {"sync_dir": "myartifacts"}
  }'
  [ "$status" -eq 0 ]
  rsync_count=$(grep -c 'myartifacts' "$MOCK_RSYNC_CALLS_FILE")
  [ "$rsync_count" -eq 2 ]
}

@test "out: reports version only once even with multiple servers" {
  run bash "$SCRIPT" "$SRC" <<< '{
    "source": {
      "servers": ["host1", "host2"],
      "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "params": {"sync_dir": "myartifacts"}
  }'
  version_count=$(echo "$output" | grep -c '"version"' || true)
  [ "$version_count" -eq 1 ]
}
