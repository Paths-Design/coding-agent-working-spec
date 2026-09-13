# Hook port qualification

Spec: `CAWS-HOOK-PORT-QUALIFICATION-001`. Started 2026-09-12.
This report grows with the approved ports; unfinished sections are not closure
claims. The harvest decisions were approved by the user in the conversation and
in `sterling-hook-harvest.md`.

## Contract

- Hook selection, handler return, adapter delivery, and native tool execution
  are separate observations. A handler's output is not automatically delivered.
- Lease freshness, transcript parentage, and session logs confer no ownership.
  Foreign lane authority survives paused or missing leases.
- Refusals survive optional logging failures. Ordinary allowed operations and
  existing surface-specific exit semantics are preservation controls.
- Corpus commands are data only. Historical outcomes are observations, not
  correctness labels. Corpus payloads and generated artifacts stay outside Git.
- Acceleration is qualified after fidelity, including sidecar-only changes and
  output corruption. A warm cache never supplies missing evidence of freshness.

## Runtime selection and session custody

`caws-hook <surface> <event> --system --describe` reports the installed runtime
digest, ordered executable paths/hashes, explicit library resolution, transcript
adapter, and differing local files that are not selected. It uses execution's
validated selection path and does not invoke handlers or write session state.
Inactive configurations return a reason instead of an empty success.

Machine dispatch retains `.caws/sessions/<resolved-session>/hook-events.jsonl`.
Each record names the invocation, handler, source digest at the before-dispatch
boundary, raw handler exit, adapter exit, and handler stdout/stderr. The
`observation_boundary: handler_return` and `delivery: not_observed` fields prevent
these observations from claiming recipient visibility. Shell command substitution
normalizes trailing stdout newlines, so this is the dispatcher's captured output,
not a byte-identical copy of an arbitrary child's original output stream.

The first installed experiment produced no records despite executing the marker:
Codex selected a duplicated surface runner. Codex and Kimi now delegate the loop
to shared code; deny priority, Codex diagnostic aliases, and Kimi's exit-1-to-2
promotion remain explicit. A second counterexample found the Codex envelope
writer following a session-directory symlink. Shared and Codex parsers now use
one envelope writer with directory-relative, no-follow opens and atomic JSON
replacement. Logging failures emit diagnostics and retain the tool decision.

### Evidence collected for this chunk

Scratch root: `/private/tmp/caws-hook-qualification-20260912/`.
The `selection-core/selection-*/` directories retain installer output,
per-scenario command/exit JSON, stdout/stderr, marker files, machine manifests,
project settings, session envelopes, and execution records.

| Command (from repository or package root as appropriate) | Exit | Observation |
|---|---:|---|
| `CAWS_EXPERIMENT_ARTIFACTS=/tmp/caws-hook-qualification-20260912/selection-core PYTHONDONTWRITEBYTECODE=1 python3 packages/caws-cli/tests/hooks/pytest/test_machine_hook_selection.py -v` | 0 | 11 tests; seven surface runners; blocked output retained; different sessions and concurrent invocations retain separate, complete records; symlink target remains empty |
| `node node_modules/jest/bin/jest.js --runInBand --runTestsByPath tests/adapter/machine-runtime.test.js tests/adapter/system-runtime.test.js` | 0 | 39 existing adapter cases, including offer retry/settlement, native output contracts, activation races, rollback, and canonical settings from worktrees |
| `../../node_modules/.bin/bats tests/hooks/bats/parse-input.bats tests/hooks/bats/parse-input-payload-transport.bats tests/hooks/bats/run-handlers-advisory-budget.bats tests/hooks/bats/run-handlers-advisory-dedup.bats` | 0 | 33 parser, large-payload, budget, and per-session advisory preservation cases |
| `node node_modules/jest/bin/jest.js --runInBand --runTestsByPath tests/init/pack-fingerprint.test.js` | 0 | 14 integrity checks; shared 69, Codex 23, Kimi 8 |
| `PYTHONDONTWRITEBYTECODE=1 python3 scripts/hook-experiments/sensitivity.py --output /tmp/caws-hook-qualification-20260912/sensitivity-core` | 0 | All three controls exit 0; corrupt recorded source digest, dropped deny priority, and removed no-follow directory opens each cause assertion failure (exit 1) |

The sensitivity summary is `sensitivity-core/summary.json`; each case retains
control/mutant stderr, command receipts, source hashes, and installed artifacts.
This is a three-defect sensitivity check, not an exhaustive mutation score.

### Limits and required further evidence

These artifacts establish installed-bootstrap behavior under synthetic native
payloads. They do not establish a fresh invocation by each real harness, recipient
visibility, or behavior under a hostile process rewriting executable bytes during
dispatch. Digests are explicitly before-dispatch observations. Fresh native
SessionStart/guard-refusal/Stop artifacts and selected installed hashes must be
examined before claiming machine-wide native adoption.

The runtime captures the returning handler's output before composition. A log
consumer must not label a budget-omitted or deduplicated advisory as delivered.
Stop's own execution record is appended after its renderer returns; it cannot
appear in that same render. Subsequent reconstruction must include it.

## Remaining approved ports

Governance operand recognition and permission-mode repair, richer transcript
fidelity, cache qualification, and hardened optional utilities/corpus experiments
remain in progress. Their acceptance evidence will be recorded separately from
the runtime-selection chunk above.
