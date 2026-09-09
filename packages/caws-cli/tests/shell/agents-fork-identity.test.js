'use strict';

/**
 * CAWS-AGENTS-FORK-IDENTITY-001 — CLI parse path + kernel write path.
 *
 * Pins the fork-aware lease surface end to end: harness_session_kind +
 * forked_from written and carried forward across throttled heartbeats,
 * hook_pid replacing the legacy pid on fresh writes (with pid fallback for
 * legacy leases), heartbeat flag validation, identity-backed conjoining
 * telemetry, and the hook template's namespace boundary + env passthrough.
 */

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const { initProject } = require('../../dist/store/init-store');
const { cleanupAll, makeTempRepo } = require('../helpers/git-repo-factory');

const CLI = path.resolve(__dirname, '..', '..', 'dist', 'index.js');
const HOOK_TEMPLATE = path.resolve(
  __dirname,
  '..',
  '..',
  'templates',
  'hook-packs',
  'shared',
  'agent-heartbeat.sh'
);

afterAll(() => {
  cleanupAll();
});

function mkRepo() {
  const root = makeTempRepo();
  const initialized = initProject(root);
  if (!initialized.ok) throw new Error('initProject failed: ' + JSON.stringify(initialized.errors));
  return root;
}

function spawnCli(root, args, env = {}) {
  return spawnSync(process.execPath, [CLI, ...args], {
    cwd: root,
    encoding: 'utf8',
    env: { ...process.env, CLAUDE_CODE_SESSION_ID: 'fork-identity-test', ...env },
  });
}

function readLease(root, sid) {
  return JSON.parse(fs.readFileSync(path.join(root, '.caws', 'leases', `${sid}.json`), 'utf8'));
}

function writeLease(root, sid, overrides = {}) {
  const leasesDir = path.join(root, '.caws', 'leases');
  fs.mkdirSync(leasesDir, { recursive: true });
  fs.writeFileSync(
    path.join(leasesDir, `${sid}.json`),
    JSON.stringify(
      {
        lease_version: 1,
        session_id: sid,
        platform: 'test',
        status: 'active',
        started_at: '2026-07-04T10:00:00.000Z',
        last_active: '2026-07-04T10:00:05.000Z',
        repo_root: root,
        cwd: root,
        git_common_dir: path.join(root, '.git'),
        git_dir: path.join(root, '.git'),
        hostname: os.hostname(),
        last_seen_reason: 'manual_register',
        ...overrides,
      },
      null,
      2
    ) + '\n'
  );
}

function recentIso(offsetMs) {
  return new Date(Date.now() + offsetMs).toISOString();
}

test('A1: heartbeat --session-kind fork --forked-from writes the fields; follow-up without flags carries them forward', () => {
  const root = mkRepo();
  const first = spawnCli(root, [
    'agents', 'heartbeat', '--session-id', 'fork-sess', '--platform', 'test',
    '--session-kind', 'fork', '--forked-from', 'parent-sess',
  ]);
  expect(first.status).toBe(0);
  let lease = readLease(root, 'fork-sess');
  expect(lease.harness_session_kind).toBe('fork');
  expect(lease.forked_from).toBe('parent-sess');
  expect(typeof lease.hook_pid).toBe('number');
  expect(lease.pid).toBeUndefined();
  // Throttled-style follow-up: context omits the fork fields.
  const second = spawnCli(root, [
    'agents', 'heartbeat', '--session-id', 'fork-sess', '--platform', 'test', '--reason', 'claim',
  ]);
  expect(second.status).toBe(0);
  lease = readLease(root, 'fork-sess');
  expect(lease.harness_session_kind).toBe('fork');
  expect(lease.forked_from).toBe('parent-sess');
});

test('A2: a legacy pid-only lease still feeds the dead-oracle fallback', () => {
  const root = mkRepo();
  // Legacy shape: pid only, no hook_pid, last_active long past the TTL.
  writeLease(root, 'legacy-sess', {
    pid: 0, // dead pid — the oracle selects dead-pid stale leases
    last_active: '2026-07-04T10:00:00.000Z',
    started_at: '2026-07-04T09:00:00.000Z',
  });
  const r = spawnCli(root, ['agents', 'prune', '--dead', '--json']);
  expect(r.status).toBe(0);
  const parsed = JSON.parse(r.stdout);
  expect(parsed.candidates).toContain('legacy-sess');
});

test('A3: invalid --session-kind and orphaned --forked-from are refused', () => {
  const root = mkRepo();
  const badKind = spawnCli(root, [
    'agents', 'heartbeat', '--session-id', 's1', '--platform', 'test', '--session-kind', 'bogus',
  ]);
  expect(badKind.status).toBe(1);
  expect(badKind.stderr).toMatch(/session-kind accepts exactly/);
  const orphan = spawnCli(root, [
    'agents', 'heartbeat', '--session-id', 's1', '--platform', 'test', '--forked-from', 'p',
  ]);
  expect(orphan.status).toBe(1);
  expect(orphan.stderr).toMatch(/only meaningful with --session-kind fork/);
});

test('A4: explicit fork identity confirms a conjoined pair without temporal overlap', () => {
  const root = mkRepo();
  writeLease(root, 'a-sess', {
    started_at: recentIso(-6 * 60 * 60 * 1000),
    last_active: recentIso(-5 * 60 * 60 * 1000),
    harness_session_kind: 'main',
  });
  writeLease(root, 'b-sess', {
    started_at: recentIso(-4 * 60 * 60 * 1000),
    last_active: recentIso(-3 * 60 * 60 * 1000),
    harness_session_kind: 'fork',
    forked_from: 'a-sess',
  });
  const text = spawnCli(root, ['agents', 'list']);
  expect(text.status).toBe(0);
  expect(text.stdout).toContain('conjoined-confirmed: b-sess -> a-sess (explicit fork identity)');
  const json = spawnCli(root, ['agents', 'list', '--json']);
  expect(json.status).toBe(0);
  const parsed = JSON.parse(json.stdout);
  expect(parsed.conjoined_pairs).toEqual([
    {
      a: 'a-sess',
      b: 'b-sess',
      parent: 'a-sess',
      child: 'b-sess',
      source: 'explicit_fork_identity',
    },
  ]);
  expect(parsed.conjoined_unresolved_pairs).toEqual([]);
  // Display-only: no lease file was modified by listing.
  const parentBefore = readLease(root, 'a-sess');
  spawnCli(root, ['agents', 'list', '--json']);
  expect(readLease(root, 'a-sess')).toEqual(parentBefore);
});

test('A5: overlap without fork identity is summarized as unresolved, never asserted pair by pair', () => {
  const root = mkRepo();
  writeLease(root, 'unknown-a', {
    started_at: recentIso(-2 * 60 * 60 * 1000),
    last_active: recentIso(-30 * 60 * 1000),
  });
  writeLease(root, 'unknown-b', {
    started_at: recentIso(-90 * 60 * 1000),
    last_active: recentIso(-15 * 60 * 1000),
  });

  const text = spawnCli(root, ['agents', 'list']);
  expect(text.status).toBe(0);
  expect(text.stdout).not.toContain('conjoined-hint:');
  expect(text.stdout).not.toContain('unknown-a <=> unknown-b');
  expect(text.stdout).toContain('conjoined-unresolved: 1 recent same-platform overlap(s) lack complete fork identity');

  const parsed = JSON.parse(spawnCli(root, ['agents', 'list', '--json']).stdout);
  expect(parsed.conjoined_pairs).toEqual([]);
  expect(parsed.conjoined_unresolved_pairs).toEqual([
    { a: 'unknown-a', b: 'unknown-b', reason: 'missing_fork_identity' },
  ]);
  expect(parsed.conjoining_identity).toEqual({
    retention_ms: 7 * 24 * 60 * 60 * 1000,
    recent_leases: 2,
    excluded_leases: 0,
    classified_leases: 0,
    unclassified_leases: 2,
    rejected_overlap_pairs: 0,
  });
});

test('A6: cross-platform overlap and two explicit main sessions are rejected', () => {
  const root = mkRepo();
  const commonWindow = {
    started_at: recentIso(-2 * 60 * 60 * 1000),
    last_active: recentIso(-30 * 60 * 1000),
  };
  writeLease(root, 'main-a', { ...commonWindow, platform: 'codex', harness_session_kind: 'main' });
  writeLease(root, 'main-b', { ...commonWindow, platform: 'codex', harness_session_kind: 'main' });
  writeLease(root, 'foreign', { ...commonWindow, platform: 'claude-code' });

  const parsed = JSON.parse(spawnCli(root, ['agents', 'list', '--json']).stdout);
  expect(parsed.conjoined_pairs).toEqual([]);
  expect(parsed.conjoined_unresolved_pairs).toEqual([]);
  expect(parsed.conjoining_identity).toEqual(expect.objectContaining({
    recent_leases: 3,
    classified_leases: 2,
    unclassified_leases: 1,
    rejected_overlap_pairs: 3,
  }));
});

test('A7: conjoining telemetry excludes leases older than seven days without changing liveness totals', () => {
  const root = mkRepo();
  const oldWindow = {
    status: 'stopped',
    started_at: recentIso(-10 * 24 * 60 * 60 * 1000),
    last_active: recentIso(-9 * 24 * 60 * 60 * 1000),
    stopped_at: recentIso(-9 * 24 * 60 * 60 * 1000),
  };
  writeLease(root, 'old-a', oldWindow);
  writeLease(root, 'old-b', oldWindow);

  const parsed = JSON.parse(spawnCli(root, ['agents', 'list', '--include-stopped', '--json']).stdout);
  expect(parsed.counts.stopped).toBe(2);
  expect(parsed.conjoined_pairs).toEqual([]);
  expect(parsed.conjoined_unresolved_pairs).toEqual([]);
  expect(parsed.conjoining_identity).toEqual(expect.objectContaining({
    recent_leases: 0,
    excluded_leases: 2,
    rejected_overlap_pairs: 0,
  }));
});

test('A8: the hook template teaches the namespace boundary and passes fork identity through', () => {
  const src = fs.readFileSync(HOOK_TEMPLATE, 'utf8');
  expect(src).toMatch(/Harness display names \(ListAgents and similar\) are NOT CAWS addresses/);
  expect(src).toMatch(/\$\{CAWS_SESSION_KIND:\+--session-kind "\$CAWS_SESSION_KIND"\}/);
  expect(src).toMatch(/\$\{CAWS_FORKED_FROM:\+--forked-from "\$CAWS_FORKED_FROM"\}/);
});
