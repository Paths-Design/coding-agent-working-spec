#!/bin/bash
# CAWS-MANAGED-HOOK
# hook_pack: codex
# hook_pack_version: 7
# caws_min_major: 11
# lineage_refs: 8,16
# edit_stance: YOURS TO EDIT. This is a starting hook, not a locked one — shape it
#   to your repo: tune thresholds, add checks, remove what does not fit. Your edits
#   are preserved: caws init treats a changed hook as intended growth and will not
#   clobber it — it shows a diff and asks (--adopt keeps yours; --overwrite --force
#   takes the upstream template). The CAWS-MANAGED-HOOK marker above is only how caws
#   init finds hooks it can offer updates for; it is NOT a keep-out sign. CAWS owns the
#   failure-class invariant (the why/what a guard protects); you own the how. The one
#   edit to avoid: gutting a guard to dodge a block instead of fixing the cause. Grow
#   everything else freely.
# Codex handler-dispatch loop (codex override).
#
# This file overrides the shared lib/run-handlers.sh for the codex surface. It
# is sourced by caws_source_lib (defined in shared/lib/agent-surface.sh) in
# preference to the shared default when:
#   $CAWS_PROJECT_DIR/$CAWS_VENDOR_DIR/hooks/lib/run-handlers.sh
# exists (i.e. .codex/hooks/lib/run-handlers.sh is present in the consumer repo).
#
# Codex-specific differences from the shared baseline:
#   1. _rh_stdout_priority recognizes "deny" as priority-3 (same as "block"),
#      since Codex uses "deny" where Claude Code uses "ask". Both cause
#      immediate short-circuit and return 2.
#   2. Dry-run env var name: accepts CODEX_HOOK_DRY_RUN in addition to
#      CAWS_HOOK_DRY_RUN (back-compat for existing codex consumer configs).
#   3. Timing env var name: accepts CODEX_HOOK_TIMING in addition to
#      CAWS_HOOK_TIMING (back-compat).
#
# The shared version accepts CAWS_HOOK_DRY_RUN / CAWS_HOOK_TIMING and also
# CLAUDE_HOOK_* legacy aliases. This override adds CODEX_HOOK_* as a third
# alias tier for codex consumers.
#
# Everything else (loop logic, stderr prefix, timing, handler resolution via
# HOOKS_DIR) is identical to the shared version.

if [[ -n "${_HOOK_RUN_HANDLERS_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
_HOOK_RUN_HANDLERS_LOADED=1

# ---------------------------------------------------------------------------
# _rh_is_truthy <value>
# Returns 0 (true) when value is non-empty and not "0".
# ---------------------------------------------------------------------------
_rh_is_truthy() {
  local val="${1:-}"
  [[ -n "$val" && "$val" != "0" ]]
}

# ---------------------------------------------------------------------------
# _rh_ms_now
# Prints current Unix time in milliseconds (integer).
# Uses date +%s%N if available, falls back to python3.
# ---------------------------------------------------------------------------
_rh_ms_now() {
  local ns
  ns=$(date +%s%N 2>/dev/null)
  # macOS date does not support %N; it prints literally "%N"
  if [[ "$ns" == *%N* ]]; then
    python3 -c 'import time; print(int(time.time() * 1000))'
  else
    printf '%d\n' "$(( ns / 1000000 ))"
  fi
}

# Codex-specific: "deny" is treated as priority-3 (immediate block/short-circuit)
# since Codex uses "deny" in place of "ask" for permission decisions.
_rh_stdout_priority() {
  local payload="$1"
  local decision
  decision=$(printf '%s' "$payload" | jq -r '.decision // .hookSpecificOutput.permissionDecision // ""' 2>/dev/null || true)
  case "$decision" in
    deny) printf '3\n' ;;
    block) printf '3\n' ;;
    ask) printf '2\n' ;;
    *) printf '1\n' ;;
  esac
}

_rh_additional_context() {
  printf '%s' "$1" | jq -er '.hookSpecificOutput.additionalContext | select(type == "string")' 2>/dev/null
}

_rh_has_additional_context_key() {
  printf '%s' "$1" | jq -e '(.hookSpecificOutput | type == "object") and (.hookSpecificOutput | has("additionalContext"))' >/dev/null 2>&1
}

_rh_merge_additional_context() {
  local envelope="$1"
  local context="$2"
  printf '%s' "$envelope" | jq -c --arg context "$context" '
    if type == "object" and (.hookSpecificOutput | type == "object") then
      .hookSpecificOutput.additionalContext = $context
    else empty end
  ' 2>/dev/null
}

_rh_byte_count() {
  LC_ALL=C printf '%s' "$1" | wc -c | tr -d ' '
}

_rh_record_offer() {
  local offer_file="$1"
  local action="$2"
  local handler="$3"
  local reason="$4"
  [[ -n "${CAWS_HOOK_SETTLEMENT_FILE:-}" && -s "$offer_file" ]] || return 0
  jq -c --arg action "$action" --arg handler "$handler" --arg reason "$reason" '
    select(type == "object" and (.id | type == "string") and (.recipient | type == "string")) |
    {offer_id: .id, recipient, action: $action, handler: $handler, reason: $reason}
  ' "$offer_file" >> "$CAWS_HOOK_SETTLEMENT_FILE" 2>/dev/null || true
}


# ---------------------------------------------------------------------------
# _rh_truncate_complete_utf8 <text> <max-bytes>
# Print the longest prefix of <text> that is at most <max-bytes> bytes AND ends
# on a character boundary.
#
# WHY THIS EXISTS (CAWS-HOOK-ADVISORY-BUDGET-TIERS-01). `head -c` can stop after
# a UTF-8 LEAD byte whose continuation bytes were cut. Such a trailing lead byte
# is an incomplete character and the harness renders it as U+FFFD. A walk-back
# that inspects the last byte of the CUT string cannot tell a complete
# multi-byte character from an orphaned lead byte: both end in a byte >= 0x80.
# The decidable question is asked at the END of the SOURCE instead. Scan the
# source's character boundaries; the final character spans [start, total). If
# that span does not fit inside max-bytes, keeping `start` bytes drops the whole
# trailing character.
#
# Pure byte arithmetic in the C locale, no external process per character. Any
# unexpected shape falls back to a plain cut so this can never fail a dispatch.
# ---------------------------------------------------------------------------
_rh_truncate_complete_utf8() {
  local text="$1"
  local max_bytes="$2"
  [[ "$max_bytes" =~ ^[0-9]+$ ]] || { printf '%s' "$text"; return 0; }
  (( max_bytes <= 0 )) && return 0

  # Byte-exact, character-safe truncation. Bash cannot express this: substring
  # expansion indexes by CHARACTER in a UTF-8 locale, and assembling the output
  # from printf %b octal escapes re-interprets them. The cut therefore lives in
  # the pack's shipped helper (advisory_truncate.py), alongside
  # classify_command.py, which is already required on this path.
  local total
  total=$(LC_ALL=C printf '%s' "$text" | wc -c | tr -d ' ')
  [[ "$total" =~ ^[0-9]+$ ]] || { printf '%s' "$text"; return 0; }
  (( total <= max_bytes )) && { printf '%s' "$text"; return 0; }

  local script out status
  script="$(_rh_pack_python_helper advisory_truncate.py)"
  if [[ -n "$script" && -f "$script" && -x "$script" ]] && command -v python3 >/dev/null 2>&1; then
    out="$(printf '%s' "$text" | python3 "$script" "$max_bytes" 2>/dev/null)"
    status=$?
    if (( status == 0 )); then
      local out_bytes
      out_bytes=$(LC_ALL=C printf '%s' "$out" | wc -c | tr -d ' ')
      # Validate the result rather than trusting it: bounded, and a byte prefix
      # of the source. A malformed response must not corrupt an advisory.
      if [[ "$out_bytes" =~ ^[0-9]+$ ]] && (( out_bytes > 0 && out_bytes <= max_bytes )) \
         && printf '%s' "$text" | head -c "$out_bytes" | cmp -s - <(printf '%s' "$out"); then
        printf '%s' "$out"
        return 0
      fi
    fi
  fi

  # Fallback: omit rather than emit a possibly split character. The caller's
  # diagnostic already reports the omission; a corrupt card would be worse.
  return 0
}

# Locate a shipped pack helper next to this library (lib/ -> pack root).
_rh_pack_python_helper() {
  local name="$1"
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local candidate
  for candidate in "${CAWS_SHARED_LIB_DIR:-}/../$name" "$here/../$name"; do
    [[ -n "$candidate" && -f "$candidate" ]] && { printf '%s' "$candidate"; return 0; }
  done
  return 0
}
# ---------------------------------------------------------------------------
# run_handlers [--short-circuit-on-block] <handler-entry>...
# ---------------------------------------------------------------------------
run_handlers() {
  local short_circuit=0
  if [[ "${1:-}" == "--short-circuit-on-block" ]]; then
    short_circuit=1
    shift
  fi

  # Ensure the input is parsed and HOOK_INPUT_JSON is available.
  # parse-input.sh is idempotent (guarded by _HOOK_PARSE_INPUT_LOADED).
  if [[ -z "${HOOK_INPUT_JSON:-}" ]]; then
    # HOOKS_DIR must be set by the caller (dispatcher boilerplate).
    # Use caws_source_lib if available (function defined in agent-surface.sh),
    # otherwise fall back to direct path.
    if command -v caws_source_lib >/dev/null 2>&1; then
      caws_source_lib parse-input.sh 2>/dev/null || return 0
    else
      # shellcheck source=parse-input.sh
      source "${HOOKS_DIR}/lib/parse-input.sh" 2>/dev/null || return 0
    fi
    parse_hook_input || return 0
  fi

  # CAWS-GUARD-REPRIEVE-SESSION-SCOPED-001: resolve the operating session id ONCE
  # so the per-handler reprieve consult gets the boundary-crossing identity (not
  # just raw HOOK_SESSION_ID, which does not propagate into agent-Bash). Best-effort:
  # a missing lib degrades to HOOK_SESSION_ID, and the reprieve check itself is
  # guarded by declare -F so a missing reprieve.sh is a no-op. Never blocks.
  local _rh_session_id="${HOOK_SESSION_ID:-}"
  if [[ "${CAWS_MACHINE_RUNTIME:-}" == 1 || -f "${HOOKS_DIR}/lib/session-id.sh" ]]; then
    # shellcheck source=lib/session-id.sh
    if [[ "${CAWS_MACHINE_RUNTIME:-}" == 1 ]]; then
      caws_source_lib session-id.sh || return 2
    else
      source "${HOOKS_DIR}/lib/session-id.sh" 2>/dev/null || true
    fi
    if declare -F resolve_caws_session_id_with_payload >/dev/null 2>&1; then
      _rh_session_id="$(resolve_caws_session_id_with_payload "${HOOK_SESSION_ID:-}")"
    fi
  fi
  # Best-effort source the reprieve lib so the loop check is available.
  if [[ "${CAWS_MACHINE_RUNTIME:-}" == 1 ]]; then
    caws_source_lib reprieve.sh || return 2
  else
    [[ -f "${HOOKS_DIR}/lib/reprieve.sh" ]] && source "${HOOKS_DIR}/lib/reprieve.sh" 2>/dev/null || true
  fi

  # Accept surface-neutral (CAWS_HOOK_*), legacy Claude (CLAUDE_HOOK_*),
  # and Codex-specific (CODEX_HOOK_*) env var names for dry-run / timing.
  local dry_run=0
  _rh_is_truthy "${CAWS_HOOK_DRY_RUN:-${CLAUDE_HOOK_DRY_RUN:-${CODEX_HOOK_DRY_RUN:-}}}" && dry_run=1

  local timing=0
  _rh_is_truthy "${CAWS_HOOK_TIMING:-${CLAUDE_HOOK_TIMING:-${CODEX_HOOK_TIMING:-}}}" && timing=1

  local max_exit=0
  local base_stdout=""
  local base_stdout_priority=0
  local advisory_template=""
  local advisory_context=""
  local advisory_budget="${CAWS_HOOK_ADVISORY_BUDGET_BYTES:-32768}"
  [[ "$advisory_budget" =~ ^[0-9]+$ ]] || advisory_budget=32768

  # Snapshot the outer $@ into an array so `set --` inside the loop can safely
  # clobber positional params without breaking iteration. Using "$@" directly
  # with `for entry in "$@"` captures at loop start on modern bash, but this
  # is safer across shells and makes the intent explicit.
  local entries
  entries=("$@")

  # CAWS-HOOKPACK-DISPATCH-EMPTY-HANDLERS-CRASH-001: bash 3.2 (macOS default
  # /bin/bash) throws "unbound variable" expanding "${entries[@]}" when
  # entries is a zero-length array under `set -u` -- even though the intended
  # behavior for zero handlers is simply "do nothing, return 0" (see below).
  # Guard on the count (always safe under set -u) instead of expanding the
  # array directly. Do not swap this for ${entries[@]:-} (silently iterates
  # once with an empty entry) or ${entries[@]+"${entries[@]}"} (this same
  # bash version has quirky behavior for that idiom in some contexts, per the
  # per-handler-args comment a few lines below) -- both were tried and ruled
  # out empirically.
  if (( ${#entries[@]} > 0 )); then

  local entry
  for entry in "${entries[@]}"; do
    # Split on whitespace: first token = script, rest = positional args.
    # shellcheck disable=SC2086
    set -- $entry
    local handler="$1"
    shift
    # "$@" now holds the handler's positional args (may be empty). Use it
    # directly rather than stashing into a local array -- bash 3.2 (macOS
    # default) has quirky ${arr[@]+"${arr[@]}"} expansion behavior for
    # empty arrays under set -u in certain command-substitution contexts.
    # "$@" has no such quirks: empty positional params under set -u is a
    # normal, non-error case.

    local handler_path="${HOOKS_DIR}/${handler}"
    if [[ "${CAWS_SYSTEM_RUNTIME:-}" == 1 ]]; then
      local system_override
      system_override="$(python3 -c 'import json,os,sys; print(json.loads(os.environ["CAWS_MACHINE_HANDLERS"]).get(sys.argv[1], ""))' "$handler")" || return 2
      [[ -z "$system_override" ]] || handler_path="$system_override"
    fi
    if [[ ! -x "$handler_path" ]]; then
      continue
    fi

    # CAWS-GUARD-REPRIEVE-SESSION-SCOPED-001: per-session guard reprieve. If the
    # operating session has an active (non-expired) reprieve that names this
    # handler, SKIP invocation entirely. Guarded by declare -F so a missing
    # reprieve.sh is a no-op (every guard runs as today). The skip is LOGGED to
    # stderr so the audit trail shows when/why a guard was skipped — a silent
    # skip is forbidden by the spec's observability invariant.
    if declare -F caws_is_handler_reprieved >/dev/null 2>&1 && \
       caws_is_handler_reprieved "$handler" "$_rh_session_id"; then
      printf '[reprieve] %s skipped for session %s (expires %s)\n' \
        "$handler" "$_rh_session_id" "${CAWS_REPRIEVE_EXPIRES_AT:-?}" >&2
      continue
    fi

    local t_start=0
    if (( timing )); then
      t_start=$(_rh_ms_now)
    fi

    local stderr_file
    stderr_file=$(mktemp)
    local handler_offer_file=""
    if [[ -n "${CAWS_HOOK_SETTLEMENT_FILE:-}" ]]; then
      handler_offer_file=$(mktemp)
      export CAWS_HANDLER_OFFER_FILE="$handler_offer_file"
    else
      unset CAWS_HANDLER_OFFER_FILE 2>/dev/null || true
    fi
    local stdout_buf
    stdout_buf=$(printf '%s' "$HOOK_INPUT_JSON" \
                  | "$handler_path" "$@" 2>"$stderr_file")
    local exit_code=$?
    local offer_action="released"
    local offer_reason="handler output was not selected"

    local t_elapsed=0
    if (( timing )); then
      local t_end
      t_end=$(_rh_ms_now)
      t_elapsed=$(( t_end - t_start ))
    fi

    # Re-emit handler stderr prefixed with handler name.
    if [[ -s "$stderr_file" ]]; then
      while IFS= read -r line; do
        printf '[%s] %s\n' "$handler" "$line" >&2
      done < "$stderr_file"
    fi
    rm -f "$stderr_file"

    # Timing annotation (after handler stderr so they don't interleave).
    if (( timing )); then
      printf '[timing] %s: %dms\n' "$handler" "$t_elapsed" >&2
    fi

    # Dry-run annotation for non-zero exits.
    if (( dry_run )) && (( exit_code != 0 )); then
      printf '[DRY-RUN] %s would have exited %d\n' "$handler" "$exit_code" >&2
      exit_code=0
    fi

    # Keep control decisions independent from bounded whole-card advisories.
    if [[ -n "$stdout_buf" ]]; then
      local stdout_priority
      stdout_priority=$(_rh_stdout_priority "$stdout_buf")
      if [[ "$stdout_priority" -eq 3 ]]; then
        _rh_record_offer "$handler_offer_file" "released" "$handler" "hard control decision omitted advisories"
        [[ -z "$handler_offer_file" ]] || rm -f "$handler_offer_file"
        printf '%s\n' "$stdout_buf"
        return 2
      fi
      local additional_context=""
      additional_context=$(_rh_additional_context "$stdout_buf" || true)
      if [[ -n "$additional_context" ]]; then
        # CAWS-HOOK-ADVISORY-BUDGET-TIERS-01. The previous check measured the
        # CUMULATIVE candidate: one oversized card did not just omit itself, the
        # running total never shrank and every later handler's advisory was
        # dropped whole for that invocation. Two properties are required, and the
        # first cut of this fix broke the second:
        #   (i)  a card that does not fit is truncated-with-marker, not dropped;
        #   (ii) truncation must LEAVE ROOM for the cards behind it, or it
        #        reproduces the very starvation it was meant to remove.
        # So truncation is capped at (available - floor), reserving
        # CAWS_HOOK_ADVISORY_CARD_FLOOR_BYTES for later handlers. Only a final
        # card that arrives with nothing left over is genuinely omitted, and that
        # omission is reported with the card's OWN size.
        local card_bytes available_bytes card_fits=0
        card_bytes=$(_rh_byte_count "$additional_context")
        if [[ -n "$advisory_context" ]]; then
          available_bytes=$(( advisory_budget - $(_rh_byte_count "$advisory_context") - 2 ))
        else
          available_bytes="$advisory_budget"
        fi
        (( available_bytes < 0 )) && available_bytes=0
        (( card_bytes <= available_bytes )) && card_fits=1
        if (( card_fits )); then
          if [[ -z "$advisory_context" ]]; then
            advisory_context="$additional_context"
          else
            advisory_context="$advisory_context"$'\n\n'"$additional_context"
          fi
          [[ -n "$advisory_template" ]] || advisory_template="$stdout_buf"
          offer_action="selected"
          offer_reason="whole advisory selected within budget"
        else
          # A card that does not fit whole may consume at most a 1/4 share of the
          # budget. A fixed reserve is not enough: with a 3000-byte budget a
          # 2000-byte card capped at (available - 256) still took 91% of it and
          # left a third card nothing, which is the same starvation shifted by one
          # position. Capping a non-fitting card at a share bounds any single
          # handler's claim on a shared resource whose other claimants are unknown
          # at this point in the chain. A budget that cannot hold every card still
          # omits the overflow -- that is the budget doing its job -- but no single
          # card can exhaust it.
          #
          # Numeric knobs are decimal-normalized before arithmetic: a value like
          # "08" is an invalid OCTAL literal to Bash and aborts the dispatch, and
          # an out-of-range value silently wraps. Anything unusable falls back to
          # the default rather than failing the hook.
          local share="${CAWS_HOOK_ADVISORY_CARD_SHARE_DIVISOR:-4}"
          [[ "$share" =~ ^[0-9]{1,9}$ ]] || share=4
          share=$(( 10#$share ))
          (( share < 1 )) && share=1
          local floor="${CAWS_HOOK_ADVISORY_CARD_FLOOR_BYTES:-256}"
          [[ "$floor" =~ ^[0-9]{1,9}$ ]] || floor=256
          floor=$(( 10#$floor ))
          local card_cap=$(( advisory_budget / share ))
          (( card_cap > available_bytes - floor )) && card_cap=$(( available_bytes - floor ))
          (( card_cap > available_bytes )) && card_cap="$available_bytes"
          (( card_cap < 0 )) && card_cap=0
          local minimum_keep=48
          local keep_bytes=0
          if (( card_cap >= minimum_keep )); then
            # The marker must be charged as content, and its own length depends on
            # the elided count, so size it once with a placeholder that can only
            # over-reserve (a placeholder of 8 nines is >= any reachable count).
            # The marker's length grows with the elided count, so reserve for
            # the ACTUAL count, not a fixed placeholder: a nine-digit elision
            # once outgrew an eight-digit reservation and emitted one byte over
            # budget. Iterate the two dependent values to a fixed point (bounded).
            local hint note_bytes try=0
            hint="… [truncated: 99999999 bytes elided]"
            note_bytes=$(_rh_byte_count "$hint")
            while (( try < 4 )); do
              local candidate_keep=$(( card_cap - note_bytes ))
              (( candidate_keep < 0 )) && candidate_keep=0
              local candidate_elided=$(( card_bytes - candidate_keep ))
              local candidate_note
              candidate_note="… [truncated: ${candidate_elided} bytes elided]"
              local candidate_note_bytes
              candidate_note_bytes=$(_rh_byte_count "$candidate_note")
              if (( candidate_note_bytes == note_bytes )); then
                break
              fi
              note_bytes="$candidate_note_bytes"
              try=$(( try + 1 ))
            done
            keep_bytes=$(( card_cap - note_bytes ))
            (( keep_bytes < 0 )) && keep_bytes=0
          fi
          if (( keep_bytes >= minimum_keep )); then
            # Cut in BYTES. Bash substring expansion indexes by CHARACTER in a
            # UTF-8 locale, so the previous `${s:0:n}` emitted roughly double the
            # byte budget for multi-byte content -- and wrapping the result in
            # `LC_ALL=C printf` did NOT help, because the expansion had already
            # happened. `head -c` is a byte-stream operation, so its unit matches
            # `_rh_byte_count` by construction. It can stop mid-character, so walk
            # back off any UTF-8 continuation byte to keep the emitted text valid,
            # then report the bytes ACTUALLY kept rather than the bytes requested.
            local truncated_card elided marker actual_kept
            truncated_card="$(_rh_truncate_complete_utf8 "$additional_context" "$keep_bytes")"
            actual_kept=$(_rh_byte_count "$truncated_card")
            elided=$(( card_bytes - actual_kept ))
            marker="… [truncated: ${elided} bytes elided]"
            truncated_card="${truncated_card}${marker}"
            if [[ -z "$advisory_context" ]]; then
              advisory_context="$truncated_card"
            else
              advisory_context="$advisory_context"$'\n\n'"$truncated_card"
            fi
            [[ -n "$advisory_template" ]] || advisory_template="$stdout_buf"
            offer_action="selected"
            offer_reason="advisory truncated to fit remaining budget"
            printf '[%s] advisory truncated: card %s bytes = %s kept + %s elided, capped at %s (budget %s)\n' \
              "$handler" "$card_bytes" "$actual_kept" "$elided" "$card_cap" "$advisory_budget" >&2
          else
            # Too little room to carry content (or to leave room for the cards
            # behind this one): declining beats emitting a marker with nothing
            # behind it, and beats consuming the last of the budget.
            printf '[%s] optional advisory omitted: card %s bytes exceeds %s available (budget %s)\n' \
              "$handler" "$card_bytes" "$available_bytes" "$advisory_budget" >&2
          fi
        fi
      elif _rh_has_additional_context_key "$stdout_buf"; then
        printf '[%s] optional advisory omitted: additionalContext must be a non-empty string\n' \
          "$handler" >&2
      elif [[ "$stdout_priority" -ge "$base_stdout_priority" ]]; then
        base_stdout="$stdout_buf"
        base_stdout_priority="$stdout_priority"
      fi
    fi
    _rh_record_offer "$handler_offer_file" "$offer_action" "$handler" "$offer_reason"
    [[ -z "$handler_offer_file" ]] || rm -f "$handler_offer_file"
    unset CAWS_HANDLER_OFFER_FILE 2>/dev/null || true

    # Short-circuit on blocking exit (exit 2), unless dry-run zeroed it.
    if (( short_circuit )) && [[ "$exit_code" -eq 2 ]]; then
      [[ -n "$base_stdout" ]] && printf '%s\n' "$base_stdout"
      return 2
    fi

    if [[ "$exit_code" -gt "$max_exit" ]]; then
      max_exit="$exit_code"
    fi
  done

  fi

  local composed_stdout="$base_stdout"
  if [[ -n "$advisory_context" ]]; then
    if [[ -n "$base_stdout" ]]; then
      composed_stdout=$(_rh_merge_additional_context "$base_stdout" "$advisory_context" || true)
      if [[ -z "$composed_stdout" ]]; then
        printf '[run-handlers] optional advisories omitted: selected control envelope cannot carry additionalContext\n' >&2
        composed_stdout="$base_stdout"
      fi
    else
      composed_stdout=$(_rh_merge_additional_context "$advisory_template" "$advisory_context" || true)
    fi
  fi
  [[ -n "$composed_stdout" ]] && printf '%s\n' "$composed_stdout"

  if (( dry_run )); then
    return 0
  fi
  return "$max_exit"
}
