#!/usr/bin/env bats
# agent-register.sh — SessionStart quarantine read
# (DANGER-LATCH-QUARANTINE-TRAP-001, A9).
#
# A session id whose danger-latch sentinel still exists is QUARANTINED. The
# SessionStart hook READS that state and reports it as additionalContext so a
# restarted trapped session learns its status before burning a command. It
# never blocks and never kills (a kill at start would loop with any
# auto-restarting harness); the trap re-engages in block-dangerous.sh on the
# first non-read-only Bash attempt.

load helpers

setup_file() {
  caws_install_pack_once
}
teardown_file() {
  caws_teardown_pack
}

_register_envelope() {
  jq -nc --arg s "$1" '{session_id:$s}'
}

_run_register() {
  local sid="$1"
  # The envelope JSON carries double quotes, so it must ride inside SINGLE
  # quotes in the bash -c string (double quotes mangle it into invalid JSON —
  # the same class _cmd_envelope_sid documents in block-dangerous.bats).
  run env \
    CAWS_PROJECT_DIR="$CAWS_TEST_REPO" \
    CAWS_AGENT_SURFACE="claude-code" \
    HOOK_CWD="$CAWS_TEST_REPO" \
    bash -c "printf '%s' '$(_register_envelope "$sid")' | bash '$CAWS_TEST_HOOKS_DIR/agent-register.sh'"
}

@test "quarantine read: a trapped session id is told it is TRAPPED at session start (A9)" {
  local sid="quar-a9-$$"
  local state_dir="$CAWS_TEST_REPO/.claude/hooks/state"
  mkdir -p "$state_dir"
  printf '{"reason":"probe"}' > "$state_dir/danger-latch-${sid}.json"
  _run_register "$sid"
  assert_success
  assert_output --partial 'QUARANTINE'
  assert_output --partial "$sid"
  assert_output --partial 'read-only'
  rm -f "$state_dir/danger-latch-${sid}.json"
}

@test "quarantine read: a session with no sentinel gets NO quarantine notice (A9 negative)" {
  local sid="quar-none-$$"
  _run_register "$sid"
  assert_success
  refute_output --partial 'QUARANTINE'
}

@test "quarantine read: never blocks even when the sentinel is malformed (fail-open advisory)" {
  local sid="quar-bad-$$"
  local state_dir="$CAWS_TEST_REPO/.claude/hooks/state"
  mkdir -p "$state_dir"
  printf 'not-json' > "$state_dir/danger-latch-${sid}.json"
  _run_register "$sid"
  assert_success
  rm -f "$state_dir/danger-latch-${sid}.json"
}
