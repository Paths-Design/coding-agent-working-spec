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

## Transcript fidelity and acceleration qualification

The installed renderer now consumes seven surface adapters, including the existing
Kimi wire contract. The Codex adapter still filters injected user-role material
using native content provenance and excludes internal analysis; its selected
machine seam delegates to shared normalization and remains callable directly.
Tool source/output records retain full Codex and Bash payloads, with explicit
length/truncation fields. Inner `functions.exec` calls are an optional source
index: comments/string literals are excluded, runtime template interpolation is
unresolved, and every projected action says `execution: not_observed`. Even an
unexecuted conditional contains syntax; the index does not prove it ran.

Turn context carries source-declared parentage with `authority: none`. Hook
sidecars are session-filtered and carry handler-return/delivery boundaries.
Malformed JSONL is diagnosed; the parser does not salvage an embedded object
from damaged text. The selected machine audit directory feeds the render.
Stop's own hook-return record remains available only to a later reconstruction.

A missing or empty transcript cannot erase existing human history, even when
new hook sidecars exist. `.render-state.json` names `retained_missing_transcript`
or `retained_empty_source`, sets `outputs_current: false`, and lists input/output
hashes. Writers take an OS lock before input reads; each turn replacement is
atomic. This is not a transactional snapshot across all turn files for readers.
An explicitly configured `CAWS_TRANSCRIPT_DATABASE` supports OpenCode/ZCode
SQLite projection in one read transaction, with session-qualified rows and an
atomic JSONL projection/receipt. Empty results replace projected bytes with an
empty file and do not reuse an old projection as a hit. Live database schemas,
compressed transcript discovery, and native subagent-store discovery remain
unverified; parent metadata is not a census of child sessions.

### Observed artifacts

Scratch root remains `/private/tmp/caws-hook-qualification-20260912/`.

- `fidelity-final/selection-3a68y0mo/repo/.caws/sessions/codex/turn-001.json`
  contains the 227-character raw program and 13,027-character error output,
  `is_error: true`, `output_truncated: false`, and parent `parent-session`
  labeled metadata with no authority. `schema-validation.json` is
  `{valid:true,errors:null}` with undeclared contract fields forbidden.
- `fidelity-final/selection-f5tdj6h9/.../codex/turn-001.json` contains the new
  `guard-fixture` sidecar, `status: blocked`, `observation_boundary: handler_return`,
  and `delivery: not_observed`. The foreign-session sidecar is absent.
- `fidelity-surfaces-after/selection-*/surface-*.command.json` retains the six
  other installed surface cases. The first run exposed Kimi's overly broad
  timestamp matcher swallowing DSH rows; the repaired matcher preserves both.
- `fidelity-database-final/selection-kidwngt8/repo/.caws/sessions/{opencode,zcode}/`
  retains projections, receipts, turns and render-state. After source-session
  deletion, the projection is empty and preserved turns are explicitly stale.
  The database byte hash remained unchanged during the read-only render.
- `fidelity-context-final/selection-*/codex-fidelity.command.json` is the final
  Codex check after repairing direct adapter imports and the unborn-branch
  `HEAD\nunknown` capture. The fixture now records branch `main`.

`python3 .../test_installed_session_fidelity.py InstalledSessionFidelity -v`
with the scratch-root environment passed the four initial scenarios (seven
surfaces), followed by passing targeted database and final Codex scenarios.
The existing renderer pytest suite passed all 48 checks using the canonical
`packages/caws-cli/tests/hooks/pytest/.venv/bin/python` (system Python lacks
pytest). The 39-case adapter run passed 38 and exposed a direct-adapter import
regression; after its repair, that exact failed test passed on a targeted rerun.
No claim that the initial full run was green is made.

### Daemon adoption refused by runtime counterexamples

Command: `python3 scripts/hook-experiments/qualify-render-daemon.py
--candidate-hooks ../sterling/.caws/hooks --output <scratch>/daemon-candidate-runtime`
(using the absolute Sterling path in the retained argv). The sandbox denied the
first loopback bind; the isolated rerun with loopback permission exited 0.
That exit means all four falsification scenarios reproduced, not adoption success.
`daemon-candidate-runtime/qualification.json` reports `adoption: refused`:

- A sidecar append returned `ok 2 0 cached`; output hash stayed
  `e41cdd1fbf01dedd05fad900e2f354df0f3a42c2a5060ff357c5d18acd4cb458` and the new
  outcome was absent.
- A corrupted turn file returned `ok 3 0 cached` and retained the corruption.
- Changed source bytes with preserved mtime returned `ok 4 0 cached`.
- An expired lease naming an unrelated experiment-owned child caused that child
  to exit -15. No live agent PID or lease was used.

The daemon/client were not installed or enabled. Before adoption, require code,
sidecar and output content hashes, no unbound PID reaping, and serialized fallback
writers, then replay timeout, concurrent writer and real process-identity cases.
Those latter cases and native latency were not verified. An idle lease alone
never establishes process identity or ownership.

`qualify-transcript-cache.py` separately compared the retained in-process parser
cache against fresh parsing: cold, unchanged, append, same-size/mtime rewrite,
truncate, inode replacement, partial line, completed partial line, and adapter
failure rollback all matched (exit 0). `transcript-cache/qualification.json`
contains event hashes and timings. The unchanged synthetic 1,000-row input took
0.34 ms cached versus 5.24 ms fresh in one measurement; this is neither a native
hook latency result nor a benchmark distribution. No warm daemon was adopted.

## Corpus replay

`replay-terminal-corpus.py` streamed all 265,615 records (1,048,757,243 bytes),
SHA256 `e6331a98ed474acaa5d8ace090366e442b9ea46843a3eab5d18aff03c2cf50b8`.
`corpus-replay-final/replay.json` records the exact command, classifier digest,
census and latency. The deterministic harness/outcome/length sample contains
698 occurrences: 598 allow, 98 ask, 2 deny; all returned, none timed out.
23 attempted context probes were replaced with explicit unavailable context.
Captured cwd, Git index, authority, adapters and environment were not restored.
These are text classifications, not historical enforcement verdicts or labels.
No false-positive/negative rate follows from historical success/denial counts.

The replay uses command text only as function input. Process/write operations
are refused by a worker audit hook; context probes cannot run Git or consume a
trusted-init token. `test_replay_boundary.py -v` exited 0: a synthetic captured
`touch` left its sentinel absent, and an injected classifier attempting a real
file write was observed as `execution_attempt_refused`. Byte offsets/hashes in
`sample.json` permit local review without copying private commands into Git.
The first replay runner used the wrong return shape and produced 698 harness
AttributeErrors; those results are invalid for classifier assessment. The corrected
run above exited 0 and all 698 rows have `status: classified`.
