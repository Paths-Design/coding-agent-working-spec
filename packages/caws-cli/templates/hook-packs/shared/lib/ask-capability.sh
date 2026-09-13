#!/bin/bash
# A prompt is a boundary only if it requires an actual human decision.
# Do not generalize bypassPermissions to other mode names without evidence.
caws_guard_cannot_ask() {
  [[ "${CAWS_GUARD_NO_ASK:-0}" == 1 ]] && return 0
  [[ "${HOOK_PERMISSION_MODE:-default}" == bypassPermissions ]] && return 0
  command -v emit_ask >/dev/null 2>&1 || return 0
  return 1
}
