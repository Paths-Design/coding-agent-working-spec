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

## Governance boundary port

The shared lexer keeps literal targets, dynamic populations, broad operations,
unrepresentable operands, and unsupported coordinate/nesting facts separate.
It recognizes executable argv positions and nested substitutions without running
command text. Option values and copy sources are excluded from mutation targets.
Worktree-operation policy consumes command positions, including nested commands;
quoted prose and file-sink heredocs do not introduce operations. No message-command
exemption remains: a sibling mutation after `caws message poll;` is checked.

Both write guards use the same early ask-capability check. `bypassPermissions`
turns unresolved-write approval requests into refusals; a benign read still
passes. Other permission mode names are not inferred to auto-approve. A linked
worktree cwd no longer bypasses foreign canonical claims; ignoring its own claim
requires a matching stamped owner. Lease absence does not release that authority.
Physical path normalization occurs before the Bash cross-repository check.

### Concrete scenario artifacts

All paths below are under `/private/tmp/caws-hook-qualification-20260912/`.
`governance/selection-goybjg2s/foreign-0.command.json` records exit 2 and
`foreign-0.stderr` names foreign worktree ownership. `preserved-1.command.json`
records exit 0 for copying the same foreign source to an owned destination.
Both receipts name the sentinel whose SHA256 remains
`53a30500b1a4c0c8193248339fc32c73b626a7a2a1ac5fea50dfa86f45882cd5`.
The sentinel was never submitted to a native tool: this is evidence of hook
classification and no side effects in the experiment, not tool prevention proof.

`governance/selection-_p884q9a/interactive-ask.stdout` contains
`permissionDecision: ask`; `automatic-block.command.json` records exit 2 and
its stderr names `mode=bypassPermissions` and `ask_dynamic_unconfined`.
`governance/selection-hgneivqg/canonical-foreign.stderr` names
`claimed:foreign:src/foreign/`. The paired own-session receipt exits 0;
the impostor-session receipt exits 2 for `claimed:mine:src/mine/`.

The installed command-position experiment is retained in
`governance-operations/selection-*/operation-*.{input.json,command.json,stdout,stderr}`.
It preserves three prose/heredoc examples and refuses three executable forms,
including `echo "$(git sparse-checkout disable)"`.
The cross-repository experiment under `governance-projections-before` exposed
an exit-0 dot-segment bypass despite a passing direct-path control. After path
normalization, `governance-projections-after` retains exit-2 refusals for direct,
`..`, and symlink projections, with the sibling sentinel unchanged.

Commands run from the lane (or package root for Bats):

- `python3 packages/caws-cli/tests/hooks/pytest/test_bash_mutation_boundary.py -v`:
  exit 0, 10 semantic tests, including multiple operands and preservation cases.
- `CAWS_EXPERIMENT_ARTIFACTS=/tmp/caws-hook-qualification-20260912/governance
  PYTHONDONTWRITEBYTECODE=1 python3 packages/caws-cli/tests/hooks/pytest/test_installed_governance_boundary.py
  InstalledGovernanceBoundary -v`: exit 0, initial three installed scenarios.
  The separately added operation and path-projection tests each subsequently
  exited 0; their retained directories above distinguish those executions.
- `../../node_modules/.bin/bats tests/hooks/bats/bash-write-guard.bats
  tests/hooks/bats/bash-write-guard-heredoc.bats tests/hooks/bats/worktree-write-guard.bats
  tests/hooks/bats/worktree-guard-base-push.bats`: exit 0, 28 preservation checks.

### What these checks could miss

This is a bounded recognizer, not a Bash evaluator. Arbitrary programs, shell
functions, aliases, interpreter payloads, and unsupported option combinations
can write files without yielding a recognized path. `cd`/Git coordinate changes
on recognized relative mutations are uncertainty, not guessed destinations.
Directory destinations and broad operations are conservative regions, not an
exact census of future writes. These guards complement the command classifier
and scope guard; these results do not prove the combined system covers every
shell mutation. Corpus replay must report unrecognized forms and latency,
without treating past successful execution as an allow label.

The existing `degraded_no_yaml` allow-with-diagnostic posture is preserved.
Canonical claim protection therefore requires examining the actual installed
oracle's dependency resolution; foreign worktree payload protection is YAML-free.
No fresh native harness approval UI, native tool non-execution, hostile filesystem
race, or global runtime adoption has been verified by this chunk. Before claiming
those, capture the native refusal and absence of its tool-result event, the selected
installed digests, and authority/path state at that same invocation boundary.
