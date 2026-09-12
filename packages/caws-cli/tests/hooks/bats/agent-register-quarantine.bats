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
  # CAWS_HOME is pinned to the isolated fixture home: caws_install_pack_once
  # exports it only inside a command substitution, so without this the pack-drift
  # check would read the real machine runtime pointer.
  run env \
    CAWS_PROJECT_DIR="$CAWS_TEST_REPO" \
    CAWS_AGENT_SURFACE="claude-code" \
    CAWS_HOME="$CAWS_TEST_HOME/.caws" \
    HOOK_CWD="$CAWS_TEST_REPO" \
    bash -c "printf '%s' '$(_register_envelope "$sid")' | bash '$CAWS_TEST_HOOKS_DIR/agent-register.sh'"
}

# ── Pack-drift advisory (HOOKPACK-STALENESS-VISIBILITY-001) ─────────────────
# Plant a machine runtime pointer + manifest that the SessionStart hook reads.
# The manifest's sha256 IS the pointer digest (machine-runtime-state.readManifest
# verifies that), so the digest is computed from the bytes actually written.
# $1 = a manifest key to publish with an all-zero hash (the "differs" file);
#      empty publishes every entry with its real installed hash ("all match").
_caws_test_sha() {
  shasum -a 256 "$1" | cut -d' ' -f1
}

_plant_runtime_manifest() {
  local mismatch="${1:-}"
  local home="$CAWS_TEST_HOME/.caws"
  local hooks="$CAWS_TEST_HOOKS_DIR"
  local staging manifest digest digest_dir
  mkdir -p "$home/state" "$home/lib/runtimes"
  staging="$(mktemp "${TMPDIR:-/tmp}/caws-manifest-XXXXXX")"
  node -e '
    const fs = require("fs");
    const crypto = require("crypto");
    const path = require("path");
    const [hooks, mismatch, out] = process.argv.slice(1);
    const keys = ["block-dangerous.sh", "agent-register.sh", "reset-danger-latch.sh"];
    const sha = (file) => crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
    const map = {};
    for (const key of keys) {
      map[key] = key === mismatch ? "0".repeat(64) : sha(path.join(hooks, key));
    }
    fs.writeFileSync(out, JSON.stringify(map));
  ' "$hooks" "$mismatch" "$staging"
  digest="$(_caws_test_sha "$staging")"
  digest_dir="$home/lib/runtimes/$digest"
  mkdir -p "$digest_dir"
  mv "$staging" "$digest_dir/manifest.json"
  printf '{"version":1,"digest":"%s","previous_digest":null}' "$digest" \
    > "$home/state/adapter-runtime.json"
}

_clear_runtime_manifest() {
  rm -rf "$CAWS_TEST_HOME/.caws/state/adapter-runtime.json" "$CAWS_TEST_HOME/.caws/lib/runtimes"
}

# Every drift test plants machine-home state; clear it so the "no pointer" case
# cannot inherit a previous test's fixture (all tests share one CAWS_TEST_HOME).
teardown() {
  _clear_runtime_manifest
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

@test "pack drift: an installed stock file differing from the pinned runtime is named (A1)" {
  local sid="drift-a1-$$"
  _plant_runtime_manifest "block-dangerous.sh"
  _run_register "$sid"
  assert_success
  assert_output --partial 'pack drift'
  assert_output --partial 'block-dangerous.sh'
}

@test "pack drift: no advisory when every installed stock file matches the runtime (A2)" {
  local sid="drift-a2-$$"
  _plant_runtime_manifest ""
  _run_register "$sid"
  assert_success
  refute_output --partial 'pack drift'
}

@test "pack drift: no advisory and exit 0 with no readable runtime pointer (A3)" {
  local sid="drift-a3-$$"
  _clear_runtime_manifest
  _run_register "$sid"
  assert_success
  refute_output --partial 'pack drift'
}

@test "pack drift: CAWS_PACK_STALENESS_CHECK=0 silences a real drift (A4)" {
  local sid="drift-a4-$$"
  _plant_runtime_manifest "block-dangerous.sh"
  run env \
    CAWS_PROJECT_DIR="$CAWS_TEST_REPO" \
    CAWS_AGENT_SURFACE="claude-code" \
    CAWS_HOME="$CAWS_TEST_HOME/.caws" \
    CAWS_PACK_STALENESS_CHECK="0" \
    HOOK_CWD="$CAWS_TEST_REPO" \
    bash -c "printf '%s' '$(_register_envelope "$sid")' | bash '$CAWS_TEST_HOOKS_DIR/agent-register.sh'"
  assert_success
  refute_output --partial 'pack drift'
}
