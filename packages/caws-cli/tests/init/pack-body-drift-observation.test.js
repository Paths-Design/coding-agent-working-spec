'use strict';

/**
 * HOOKPACK-COPIED-PACK-LAG-VISIBILITY-001 A4 —
 * observeSharedPackBodyDrift against a REAL install.
 *
 * The version stamp is not a freshness proxy. `installHookPack` stamps
 * `hook_pack_version: <cli-version>` into the project copy while the template
 * literal stays frozen, and manifest-shared.ts records content changes that
 * landed WITHOUT a version bump. A comparison that keys on the version number
 * therefore cannot prove the copied pack matches what this CLI ships.
 *
 * These tests install the shipping SHARED_PACK with the shipping installer and
 * then observe the copied pack — so "matches" is a genuine end-to-end property
 * of the real write path, not a hand-built expectation. A hand-built fixture
 * that hashes the installed files to synthesize the expected manifest is
 * tautological and cannot observe install-time divergence at all.
 */

const fs = require('fs');
const path = require('path');
const { makeTempRepo, cleanupAll } = require('../helpers/git-repo-factory');
const { SHARED_PACK } = require('../../dist/init/hook-packs/manifest-shared');
const {
  installHookPack,
  observeSharedPackBodyDrift,
} = require('../../dist/init/hook-install');

const DEST = '.caws/hooks/block-dangerous.sh';

describe('observeSharedPackBodyDrift (A4)', () => {
  let repo;

  beforeAll(() => {
    repo = makeTempRepo();
    installHookPack(SHARED_PACK, { repoRoot: repo });
  });

  afterAll(() => cleanupAll());

  const destAbs = (rel) => path.join(repo, rel);

  test('a byte-pristine install reports no body drift', () => {
    expect(observeSharedPackBodyDrift(repo)).toEqual([]);
  });

  test('re-stamping only the version header is NOT body drift', () => {
    // The load-bearing normalization case: a file that differs from the
    // template by the version line alone predates the current pack version and
    // carries no local growth. Reporting it would be a false positive on every
    // clean install (the defect class this observation exists to avoid).
    const original = fs.readFileSync(destAbs(DEST), 'utf8');
    const restamped = original.replace(
      /^(#\s*hook_pack_version:\s*)\d+/m,
      '$1999'
    );
    expect(restamped).not.toBe(original);
    fs.writeFileSync(destAbs(DEST), restamped);
    try {
      expect(observeSharedPackBodyDrift(repo)).toEqual([]);
    } finally {
      fs.writeFileSync(destAbs(DEST), original);
    }
  });

  test('a genuine body edit names exactly that file', () => {
    const original = fs.readFileSync(destAbs(DEST), 'utf8');
    fs.writeFileSync(destAbs(DEST), `${original}\n# repo-local edit\n`);
    try {
      expect(observeSharedPackBodyDrift(repo)).toEqual([DEST]);
    } finally {
      fs.writeFileSync(destAbs(DEST), original);
    }
  });

  test('a second edit is named in sorted order and the first is not sticky', () => {
    const one = destAbs(DEST);
    const two = destAbs('.caws/hooks/audit.sh');
    const originalOne = fs.readFileSync(one, 'utf8');
    const originalTwo = fs.readFileSync(two, 'utf8');
    fs.writeFileSync(one, `${originalOne}\n# edit one\n`);
    fs.writeFileSync(two, `${originalTwo}\n# edit two\n`);
    try {
      expect(observeSharedPackBodyDrift(repo)).toEqual([
        '.caws/hooks/audit.sh',
        DEST,
      ]);
    } finally {
      fs.writeFileSync(one, originalOne);
      fs.writeFileSync(two, originalTwo);
    }
    // Restoring both clears the observation — it is a pure function of disk.
    expect(observeSharedPackBodyDrift(repo)).toEqual([]);
  });

  test('a missing copied pack yields an empty observation, never a throw', () => {
    const empty = makeTempRepo();
    expect(observeSharedPackBodyDrift(empty)).toEqual([]);
  });
});
