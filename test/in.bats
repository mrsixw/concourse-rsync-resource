#!/usr/bin/env bats

load helpers

SCRIPT="$BATS_TEST_DIRNAME/../assets/in"

setup() {
  setup_mocks
  DEST="$BATS_TEST_TMPDIR/dest"
  mkdir -p "$DEST"
  export BUILD_PIPELINE_NAME="mypipeline"
  export BUILD_ID="42"
}

# Scripts print debug lines to stderr; bats mixes stderr+stdout into $output.
# The JSON payload is always the last line, so we extract it with ${lines[-1]}.

# ---------------------------------------------------------------------------
# Output JSON
# ---------------------------------------------------------------------------

@test "in: outputs version ref as JSON" {
  # The current code emits \$MD5_STRING (undefined) rather than \$VERSION —
  # this test documents the *intended* behaviour and will fail until that bug
  # is fixed.
  export MOCK_SSH_TEST_EXIT=0
  run bash "$SCRIPT" "$DEST" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "version": {"ref": "abc123"}
  }'
  [ "$status" -eq 0 ]
  ref=$(echo "${lines[-1]}" | jq -r '.version.ref')
  [ "$ref" = "abc123" ]
}

# ---------------------------------------------------------------------------
# Error cases
# ---------------------------------------------------------------------------

@test "in: exits 1 when version ref is empty" {
  run bash "$SCRIPT" "$DEST" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "version": {}
  }'
  [ "$status" -eq 1 ]
}

@test "in: exits 1 when version directory does not exist on server" {
  export MOCK_SSH_TEST_EXIT=1
  run bash "$SCRIPT" "$DEST" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "version": {"ref": "abc123"}
  }'
  [ "$status" -eq 1 ]
}

# ---------------------------------------------------------------------------
# rsync source path
# ---------------------------------------------------------------------------

@test "in: rsync uses base_dir/version as source when disable_version_path false" {
  export MOCK_SSH_TEST_EXIT=0
  run bash "$SCRIPT" "$DEST" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "version": {"ref": "abc123"}
  }'
  grep '/sync/dir/abc123' "$MOCK_RSYNC_CALLS_FILE"
}

@test "in: rsync uses base_dir directly when disable_version_path true" {
  export MOCK_SSH_TEST_EXIT=0
  run bash "$SCRIPT" "$DEST" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy",
      "disable_version_path": true
    },
    "version": {"ref": "abc123"}
  }'
  grep '/sync/dir' "$MOCK_RSYNC_CALLS_FILE"
  ! grep '/sync/dir/abc123' "$MOCK_RSYNC_CALLS_FILE"
}

# ---------------------------------------------------------------------------
# SSH port
# ---------------------------------------------------------------------------

@test "in: defaults to port 22 when port not specified" {
  export MOCK_SSH_TEST_EXIT=0
  run bash "$SCRIPT" "$DEST" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "version": {"ref": "abc123"}
  }'
  grep -- '-p 22' "$MOCK_SSH_CALLS_FILE"
}
