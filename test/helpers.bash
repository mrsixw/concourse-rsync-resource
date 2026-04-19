#!/usr/bin/env bash
# Shared bats setup: creates mock executables and wires up a temp HOME.

setup_mocks() {
  MOCK_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$MOCK_BIN"

  # ssh-agent: emit valid eval-able shell so scripts don't error
  cat > "$MOCK_BIN/ssh-agent" << 'EOF'
#!/usr/bin/env bash
echo "SSH_AUTH_SOCK=/tmp/mock-ssh-agent.sock; export SSH_AUTH_SOCK;"
echo "SSH_AGENT_PID=99999; export SSH_AGENT_PID;"
EOF

  cat > "$MOCK_BIN/ssh-add" << 'EOF'
#!/usr/bin/env bash
exit 0
EOF

  # ssh: behaviour controlled by exported env vars set in each test
  cat > "$MOCK_BIN/ssh" << 'EOF'
#!/usr/bin/env bash
echo "$*" >> "${MOCK_SSH_CALLS_FILE:-/dev/null}"
case "$*" in
  *"test -d"*)  exit "${MOCK_SSH_TEST_EXIT:-0}" ;;
  *"ls -1t"*)   cat "${MOCK_SSH_LS_FILE:-/dev/null}"; exit 0 ;;
  *"mkdir"*)    exit "${MOCK_SSH_MKDIR_EXIT:-0}" ;;
  *"[ -d"*)     exit "${MOCK_SSH_TEST_EXIT:-0}" ;;
  *)            exit "${MOCK_SSH_EXIT:-0}" ;;
esac
EOF

  cat > "$MOCK_BIN/rsync" << 'EOF'
#!/usr/bin/env bash
echo "$*" >> "${MOCK_RSYNC_CALLS_FILE:-/dev/null}"
exit "${MOCK_RSYNC_EXIT:-0}"
EOF

  # Predictable md5sum output so out tests can assert on the hash
  cat > "$MOCK_BIN/md5sum" << 'EOF'
#!/usr/bin/env bash
echo "aabbcc112233aabbcc112233aabbcc11  -"
EOF

  chmod +x "$MOCK_BIN"/*

  export MOCK_SSH_CALLS_FILE="$BATS_TEST_TMPDIR/ssh_calls"
  export MOCK_RSYNC_CALLS_FILE="$BATS_TEST_TMPDIR/rsync_calls"
  touch "$MOCK_SSH_CALLS_FILE" "$MOCK_RSYNC_CALLS_FILE"

  export MOCK_SSH_LS_FILE="$BATS_TEST_TMPDIR/ls_output"
  touch "$MOCK_SSH_LS_FILE"

  # Redirect HOME so scripts write ~/.ssh/* into a throwaway dir
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"

  export PATH="$MOCK_BIN:$PATH"
}

teardown() {
  # scripts run `chmod -R 600 ~/.ssh` which sets the directory itself to 600
  # (no execute bit), preventing bats from cleaning up BATS_TEST_TMPDIR.
  chmod -R u+rwX "$HOME" 2>/dev/null || true
}
