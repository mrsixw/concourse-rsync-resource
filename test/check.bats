#!/usr/bin/env bats

load helpers

SCRIPT="$BATS_TEST_DIRNAME/../assets/check"

setup() {
  setup_mocks
}

# Scripts print debug lines to stderr; bats mixes stderr+stdout into $output.
# The JSON payload is always the last line, so we extract it with ${lines[-1]}.

# ---------------------------------------------------------------------------
# disable_version_path: true  →  base_dir itself is the single version
# ---------------------------------------------------------------------------

@test "check: disable_version_path true returns base_dir basename as ref" {
  export MOCK_SSH_TEST_EXIT=0
  run bash "$SCRIPT" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/mydir",
      "private_key": "dummy",
      "disable_version_path": true
    },
    "version": {}
  }'
  [ "$status" -eq 0 ]
  result=$(echo "${lines[-1]}" | jq -r '.[0].ref')
  [ "$result" = "mydir" ]
}

@test "check: disable_version_path true returns empty array when dir absent" {
  export MOCK_SSH_TEST_EXIT=1
  run bash "$SCRIPT" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/mydir",
      "private_key": "dummy",
      "disable_version_path": true
    },
    "version": {}
  }'
  [ "$status" -eq 0 ]
  count=$(echo "${lines[-1]}" | jq 'length')
  [ "$count" -eq 0 ]
}

# ---------------------------------------------------------------------------
# disable_version_path: false / absent  →  list subdirectory versions
# ---------------------------------------------------------------------------

@test "check: no current version returns all dirs oldest-first" {
  printf 'v3\nv2\nv1\n' > "$MOCK_SSH_LS_FILE"
  run bash "$SCRIPT" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "version": {}
  }'
  [ "$status" -eq 0 ]
  count=$(echo "${lines[-1]}" | jq 'length')
  [ "$count" -eq 3 ]
  first=$(echo "${lines[-1]}" | jq -r '.[0].ref')
  last=$(echo  "${lines[-1]}" | jq -r '.[-1].ref')
  [ "$first" = "v1" ]
  [ "$last"  = "v3" ]
}

@test "check: with current version returns only that version and newer" {
  printf 'v3\nv2\nv1\n' > "$MOCK_SSH_LS_FILE"
  run bash "$SCRIPT" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "version": {"ref": "v2"}
  }'
  [ "$status" -eq 0 ]
  count=$(echo "${lines[-1]}" | jq 'length')
  [ "$count" -eq 2 ]
  first=$(echo "${lines[-1]}" | jq -r '.[0].ref')
  last=$(echo  "${lines[-1]}" | jq -r '.[-1].ref')
  [ "$first" = "v2" ]
  [ "$last"  = "v3" ]
}

@test "check: empty remote listing returns empty array" {
  : > "$MOCK_SSH_LS_FILE"
  run bash "$SCRIPT" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "version": {}
  }'
  [ "$status" -eq 0 ]
  count=$(echo "${lines[-1]}" | jq 'length')
  [ "$count" -eq 0 ]
}

# ---------------------------------------------------------------------------
# SSH invocation details
# ---------------------------------------------------------------------------

@test "check: defaults to port 22 when port is not specified" {
  printf 'v1\n' > "$MOCK_SSH_LS_FILE"
  run bash "$SCRIPT" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy"
    },
    "version": {}
  }'
  grep -- '-p 22' "$MOCK_SSH_CALLS_FILE"
}

@test "check: uses custom port when specified" {
  printf 'v1\n' > "$MOCK_SSH_LS_FILE"
  run bash "$SCRIPT" <<< '{
    "source": {
      "server": "myhost", "user": "bob",
      "base_dir": "/sync/dir",
      "private_key": "dummy",
      "port": 2222
    },
    "version": {}
  }'
  grep -- '-p 2222' "$MOCK_SSH_CALLS_FILE"
}
