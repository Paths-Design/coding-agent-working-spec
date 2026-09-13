# Hook port qualification

Spec: `CAWS-HOOK-PORT-QUALIFICATION-001`. Started 2026-09-12.
The harvest decisions were approved by the user in the conversation and in
`sterling-hook-harvest.md`. This is local source and isolated installed-runtime
qualification. Global installation and fresh native harness adoption are separate
follow-on work, not established by this report.

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

## Port decisions

Selected-code diagnostics, shared command recognition, tenure/permission repairs,
transcript fidelity, and optional consumer utilities were ported and exercised.
The daemon was qualified and rejected on concrete counterexamples; its code is
not shipped. The in-process parser cache remains bounded by content validation.
Corpus replay does not establish classifier accuracy or historical enforcement.

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
- `fidelity-final/selection-f5tdj6h9/repo/.caws/sessions/codex/turn-001.json` contains the new
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
That historical exit meant all four predicates matched, not adoption success.
Review subsequently found the source-change predicate insufficient: an `ok`
response and a comment-only edit cannot establish stale execution. The behavioral
replacement and independently executed controls are recorded below.
`daemon-candidate-runtime/qualification.json` reports `adoption: refused`:

- A sidecar append returned `ok 2 0 cached`; output hash stayed
  `e41cdd1fbf01dedd05fad900e2f354df0f3a42c2a5060ff357c5d18acd4cb458` and the new
  outcome was absent.
- A corrupted turn file returned `ok 3 0 cached` and retained the corruption.
- Changed source bytes with preserved mtime returned `ok 4 0 cached`; this original
  observation alone did not establish a source-freshness counterexample.
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


## Optional consumer utilities

`hook-utilities.sh` is shipped as an optional extension and is absent from default
chains. With no `CAWS_OPTIONAL_HOOK_POLICY`, it emits nothing. An explicit consumer
JSON file may contain:

```json
{
  "version": 1,
  "rg_replace": true,
  "ignored_staging": true,
  "focused_tests": {"executables": ["pytest"], "entry_point": "scripts/test"},
  "documents": {"roots": ["docs/"], "required_frontmatter": ["title", "status"]}
}
```

Set `CAWS_OPTIONAL_HOOK_POLICY` to that file's absolute path in the consumer
harness environment. Add `{"handler":"hook-utilities.sh","before":null}` to
its reviewed `extensions.pre_tool_use` policy using the existing
[`init adapters migrate --from` workflow](../guides/hook-packs.md); preserve the
consumer's other reviewed entries. No machine/project policy was globally enabled
in this task. A migrated consumer's configuration update must retain its reviewed
native registration and be checked through `--describe` and a real invocation.

Replacement search is advisory because `-r n` can be intentional. Command
positions, wrappers, option values, literal prose and `--` are distinguished.
Focused-test advice grants no resource admission. Document checks are configurable
frontmatter-key presence notices on Write, not YAML semantic validation, Edit
coverage or repository-wide documentation enforcement.

Forced staging uses fixed read-only Git ignored-path queries and supports literal
cwd, `-C`, whole-tree selection, NUL pathspec files, literal pathspec mode and
tracked-only updates. Only confirmed ignored-file selection blocks. Dynamic or
complex shell coordinates, unsupported options, quoted pathspec decoding and
unavailable pathspecs produce visible unresolved advice. These utilities are not
an exhaustive shell/Git enforcement boundary. File/pathspec races and exotic Git
environment semantics remain outside the verified envelope.

### Installed artifacts and counterexamples

`python3 packages/caws-cli/tests/hooks/pytest/test_installed_hook_utilities.py
InstalledHookUtilities -v` exited 0 (three scenarios, 78.919 s) with
`CAWS_EXPERIMENT_ARTIFACTS=<scratch>/utilities-isolated`. This includes repeated
subcases, not a per-hook latency measurement. Retained receipts contain exact
native payload, argv, runtime digest and exit status:

- `utilities-isolated/selection-i1sse5k9/ignored-0.command.json`: captured
  `git add -f private.generated` returns 2; `ignored-0.stdout` names the file.
- The same directory's `stage-preserved-1.command.json` returns 0 for source
  staging, and `stage-unresolved-0.stdout` explicitly declines a subshell cwd
  guess. Ordinary add, dry-run, tracked-only update and literal wildcard
  preservation cases returned 0.
- `utilities-isolated/selection-yrc7m1tp/replace-0.stdout` says
  `Ripgrep replacement is active`; quoted prose and option-value controls are quiet.
- `utilities-isolated/selection-x46zrfvr/document-large.stdout` contains
  `Consumer document metadata missing: title, status.` for a 125,000-character
  input transported through the payload file.

The first installed run exposed a real no-op: the utility read unavailable
`HOOK_INPUT_JSON` instead of `HOOK_TOOL_INPUT_JSON` for small inputs. All three
scenarios failed until the transport was repaired. Subsequent failures came from
fixture assumptions: repeated same-session notices are deliberately deduplicated,
and Claude block JSON stays on stdout. Independent cases now use separate session
identities and inspect the correct surface output. This does not disable or evade
production deduplication.

## Concurrent rendering sensitivity

The installed renderer's controlled two-process scenario exited 0. In
`fidelity-concurrent/selection-lv8dm0ps/lock-observation.json`, the first process
is inside its adapter, the second has attempted rendering, and
`second_blocked_before_read` is true. Both command exits are 0; final
`repo/.caws/sessions/codex/turn-001.json` contains `second snapshot` and its hash
matches `.render-state.json` with `outputs_current: true`.

`python3 scripts/hook-experiments/sensitivity.py --case renderer-lock --output
<scratch>/sensitivity-renderer-lock` exited 0. The control exits 0; deleting
`fcntl.flock` only in a disposable template copy causes exit 1 at the exact
assertion `second renderer read inputs while first held the lock`. Both installed
runtimes, commands, source hashes and outputs are retained in
`sensitivity-renderer-lock/summary.json` and its referenced directories. This is
one additional defect sensitivity check, not exhaustive race coverage. The test
uses a controlled adapter for scheduling; it does not prove native scheduling,
crash recovery, host-path race safety or a multi-file reader transaction.

## Proof boundaries before broader adoption

A passing suite could still hide unsupported executable wrappers, interpreter
payloads, unmodeled shell/Git options, stale native registrations, missing source
rows, a live database schema mismatch, or lost delivery after handler return.
Syntax-indexed inner actions do not establish execution; parentage and leases do
not establish ownership. A source digest taken before dispatch does not bind an
executable against hostile replacement while running.

Before claiming deployment or native protection, examine a fresh harness sequence:
selected paths/digests, SessionStart envelope, a harmless foreign-owned write
refusal with unchanged sentinel, delivered guard output, and Stop turn artifacts
with matching sidecar/input/output hashes. Verify the consumer's actual YAML/oracle
dependencies and native permission modes. For database discovery, inspect a live
schema and source-row custody receipt. For classifier accuracy, add independently
adjudicated labels and reconstructed authority/context states. Daemon adoption
requires repairing and replaying all four counterexamples plus process-identity,
timeout, concurrent-writer and native-latency experiments.

Not verified: global machine installation, fresh real native harness execution,
recipient-visible delivery, actual tool nonexecution after a native refusal,
live OpenCode/ZCode databases, compressed/native child transcript discovery,
arbitrary shell semantics, hostile filesystem races, or classifier error rates.


The strengthened staging rerun uses an actual prepopulated Git index and retains
`utilities-index-custody/selection-*/preservation.json` with before/after index and
ignored-sentinel SHA256 values. The targeted installed scenario exited 0 (36.820 s);
all captured command strings remained data. Only explicit fixture setup populated
the scratch Git index. The before/after index and sentinel hashes match.

## Final local validation

Shared pack 72, Codex 24 and Kimi 8 are the qualified source distribution. The
shared fingerprint is
`4c0286f98d2c5177d772f3998a34c9d5f774ddb32b910d75b2f769a861178d7a`.
The final fingerprint command exited 0 (14 checks), and the shared command lexer
suite exited 0 (10 checks, 2.468 s). The package build passed after the optional
manifest registration. Generated installed runtimes, corpus replay, mutants and
logs remain under the scratch root, outside the source ledger.

`final-checks/` retains command/exit/stdout/stderr receipts for claim, doctor,
gates and whitespace validation. All five declared gates pass; this does not
establish native behavior or comprehensive semantic correctness. Doctor exits 1
with 1 error, 7 warnings and 14 informational findings: the error is another
session's removed `wt-advisory-budget` cwd, and the warnings include existing
legacy pack drift and missing foreign-owner leases. Those states were not repaired
or taken over. The selected global runtime remains the previously installed
version; source qualification does not silently replace it.

## Review repairs, 2026-09-13

Spec: `CAWS-HOOK-REVIEW-REPAIRS-001`. The seven must-fix findings were handled
before the experiment-verdict repair. Artifacts below are retained under
`/private/tmp/caws-hook-repairs-20260913/`; they are generated local evidence,
not tracked source or a claim of remote CI/native deployment.

| Finding | Repair and regression evidence |
|---|---|
| Mutations hidden by redirections or absolute wrappers | Preserve argv across redirections, including option values and FD prefixes, and recognize absolute `env`. `governance-red.command.json` exits 1; `governance-green.command.json` exits 0 (19 tests). `governance-observations.json` retains installed foreign refusals (2), owned destination/read-source/prose admissions (0), and the unchanged sentinel SHA256. `redirection-fd-red.stderr` records the quoted-numeric-operand counterexample; `mutation-green.command.json` exits 0 after repair (12 tests). |
| Repeat initialization refuses newly managed support files | The earlier header lane supplied the repair. `reinit/summary.json` records two real `node <lane>/packages/caws-cli/dist/index.js init --agent-surface codex` calls, both exit 0. `reinit/second.stdout` reports `Unchanged (73)`; all 144 hashed hook/pristine files retain their bytes. `distribution-jest.command.json` exits 0 (81 installation/header/fingerprint cases). |
| Logical versus physical root causes false refusal | Normalize both sides of the cross-repository comparison. `governance-observations.json` records logical/physical root controls: own writes 0, foreign writes 2. `governance-bats.command.json` exits 0 (24 cases using ordinary macOS TMPDIR). |
| Kimi structured output crashes | Restore the JSON import; exercise string, object, list, null and zero through installed Stop. `logging-red.stderr` contains the prior NameError. Installed fixtures retain each result in `kimi-result-<n>.turn.json`, including Unicode and error status. |
| Every handler blamed for a chain refusal | Derive status from each handler's own exit/envelope and retain adapter exit separately. `attribution-red.stderr` records all three handlers incorrectly blocked. The repaired mixed turn contains `success.sh=completed`, `ask.sh=ask`, `deny.sh=block`, raw exits all 0, adapter exits all 2, and `delivery=not_observed`. |
| Surface defaults lost through shared delegation | Codex supplies its own default without overriding an explicit platform; Kimi retains exit promotion without bootstrap flags. `logging-observations.json` records default `codex`, explicit `dsh`, and Kimi exits `0→0, 1→2, 2→2`. `logging-bats.command.json` exits 0 (35 preservation cases). |
| pytest assumes prebuilt installer | `pretest:pytest` runs the production build. `entrypoint-red.stderr` reproduces `MODULE_NOT_FOUND` in a source-only package. `entrypoint-green.command.json` exits 0; `entrypoint-*/command.json` records dist absent before/build present after, and `selection-*/repo/marker.log` contains `invoked`. The regression narrows the inner test command; build and runtime are real. Pip installation and remote CI are outside this control. |

The installed logging run in `logging-green.command.json` exits 0 (52 tests).
`logging-jest.command.json` exits 0 (82 adapter, resolver and fingerprint cases).
The initial mixed-chain fixture incorrectly expected a handler after a deny to
execute; that fixture was corrected before the decision-bearing red run in
`attribution-red`. Later fixtures preserve separate dispatch and render receipts
and each Kimi turn snapshot so successive renders cannot overwrite the evidence.
Shared/Codex/Kimi pack versions are 75/25/9, with updated fingerprint baselines.

### Discriminating daemon qualification

The source probe appends an execution marker to a disposable renderer copy,
changes `source-a` to same-length `source-b`, and preserves mtime. An independent
fresh interpreter must execute `source-b` and produce a parseable turn before the
warm request is judged. Missing or malformed markers are instrumentation failures,
not successful qualification. Exit 0 now means a completed experiment; the report's
adoption field separately remains `refused` or `unproven`.

`daemon-controls.command.json` exits 0 (four controls). Real renderer calls using
cached and freshly loaded modules return identical `ok 2 1 rendered` responses;
`source-control-*/source-freshness.json` distinguishes their markers and verdicts.
These are controlled module-cache tests, not a native daemon transport claim.
Missing cold and missing warm markers each raise instead of producing a verdict.

The real candidate replay is `daemon-candidate-loopback.command.json` (exit 0).
The first sandboxed attempt could not bind loopback; the approved rerun used only
experiment-owned child processes. Its `qualification.json` retains:

- Sidecar append: `ok 2 0 cached`; before and after output SHA256 both
  `6352b2af4181a9c689c88a8c3c02e4a07e14be8a7c74e3acd9caabf182ab139c`;
  `new_observation_present` is false.
- Corrupted output: `ok 3 0 cached`; output remains
  `corrupted same-count artifact`.
- Source change: mtime and size both preserved; fresh process 46295 emits
  `source-b`, while the warm marker remains `source-a` from process 46091.
  `fresh-source.command.json`, `fresh-source-control/turn-001.json` and both
  `.qualification-source-execution.json` files retain independent evidence.
- The reaper exits 0 and the unrelated experiment-owned child 46426 exits -15.
  This is an ownership-binding counterexample, not actual OS PID-reuse proof.

The candidate remains refused and unshipped. Before adopting it, inspect a replay
with code/sidecar/output content validation, process-start identity binding, and
serialized fallback writers; then examine timeout and concurrent-write receipts.

`daemon-reloading-control.command.json` supplies the other direction over real
loopback transport (exit 0). Its disposable daemon reloads the renderer and
bypasses the render-result cache on each request; `reloading-control-input/control.json`
records the exact change and hashes. The warm process 95438 and independent
process 95488 both emit `source-b`; source freshness has `counterexample: false`.
Sidecar inclusion and corruption repair also become observable. The remaining
reaper counterexample keeps adoption refused. This intentionally slow control is
not a proposed production daemon patch or a latency result.

### Test sensitivity and proof limits

`repair-sensitivity/summary.json` records matched green controls (exit 0) and
assertion failures (exit 1) after deliberately restoring chain-wide blame and
Codex's wrong default in disposable template copies. The failures match the
specific attribution/platform assertions. This establishes sensitivity for one
selected defect in each of `session_log_renderer.py` and Codex `parse-input.sh`;
it is not an exhaustive per-file mutation score. Governance and Kimi defects
also have incident-matched red/green fixtures rather than pass counts alone.

Tests could still pass while a harness selects older installed bytes, ignores a
denial, or never delivers an advisory. No global runtime was updated; no fresh
native harness activation, recipient visibility, actual prevented tool write,
remote CI, classifier accuracy, or production latency was verified here. Before
making those claims, inspect native SessionStart/PreToolUse/Stop records, selected
paths/digests, actual refused/allowed tool results, and resulting files. The shell
recognizer remains a bounded parser; these regressions do not establish complete
Bash grammar coverage. Corpus commands were not executed or relabeled.

### Final validation for the repair lane

Every command below has a corresponding `<label>.command.json`, `.stdout` and
`.stderr` under the repair scratch root. These receipts include cwd, argv, exit
and duration; the installed pytest fixtures additionally retain runtime files.

| Label / command | Exit | Observed result |
|---|---:|---|
| `full-pytest`: `<pytest-venv>/bin/python -m pytest -q packages/caws-cli/tests/hooks/pytest` | 0 | 225 passed; 17 pre-existing datetime deprecation warnings. `full-pytest/selection-c329a2_j/kimi-result-1.turn.json` retains `{"text": "résultat", "count": 0}` with `is_error: true`; the other four snapshots retain string, list, null and zero. `selection-iw55i6zy/mixed-handlers.command.json` retains dispatch exit 2 and the deny envelope, separately from the Stop render receipt. |
| `full-jest`: `node <repo>/node_modules/jest/bin/jest.js --runInBand` from the CLI package | 0 | 2,761 passed across 220 suites (1,244.668 seconds). |
| `full-bats`: `node_modules/.bin/bats packages/caws-cli/tests/hooks/bats packages/caws-cli/tests/hooks/bats-macos` | 1 | 275 passed, seven process-identity fixtures failed inside the sandbox. `sandbox-ps.json` records `PermissionError: Operation not permitted` when launching `ps`. |
| `bats-process-controls`: Bats with the seven failed names selected across `block-dangerous.bats`, `session-id-agent-pid.bats`, `session-id-canonical.bats` | 0 | All seven pass unchanged with approved process access. These existing fixtures clean up their sentinel files; their retained evidence is the TAP output, not a preserved native session trace. The full suite was not rerun outside the sandbox. |
| `build-logging`, `final-typecheck`, `final-lint`: package build, typecheck and lint | 0 | TypeScript compilation/checks and ESLint pass; Bash syntax checks pass for 64 scripts. Informational ShellCheck warnings remain in the retained lint output. |
| `entrypoint-artifacts`: source-only entrypoint regression with a previously absent artifact directory | 0 | Real build and installed marker pass; the requested scratch root is created and receipts retained. This is the only test-source adjustment after the full pytest run. |
| `final-gates`: `caws gates run --spec CAWS-HOOK-REVIEW-REPAIRS-001` | 0 | All five declared gates pass, zero violations. |
| `final-doctor`: installed `caws doctor`; `source-doctor`: built CLI `doctor` | 1 | Existing foreign session's missing `wt-advisory-budget` cwd and seven warnings remain. Built CLI reports 1E/7W/15I; installed CLI reports 1E/7W/14I. No foreign ownership or machine configuration was changed. |

The passing rerun closes the process-access explanation for those seven fixture
failures. It does not establish actual OS PID reuse, a global runtime update, or
any native harness delivery claim. The read-only lane review reports every source
commit in scope; acceptance evidence is recorded separately through the CAWS CLI.
