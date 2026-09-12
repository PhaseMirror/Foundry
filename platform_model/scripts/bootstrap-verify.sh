#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
archive="$root/.prism/cache/bootstrap/prismpm-0.2.0-x86_64-unknown-linux-gnu.tar.gz"
archive_sha=f3dd999f5618db154fa06222a06f9de95d86e1dbf683954426ea91c974cbe24c
source_commit=f378fd3a8dc5711cb4b22cec9ee2f874353628c3
work=$(mktemp -d /tmp/prismpm-bootstrap-verify.XXXXXX)
cleanup() {
  rm -rf "$work"
}
trap cleanup EXIT

test -f "$archive"
printf '%s  %s\n' "$archive_sha" "$archive" | sha256sum --check --strict >/dev/null
tar --extract --gzip --file "$archive" --directory "$work" \
  --no-same-owner --no-same-permissions
prior="$work/prismpm-0.2.0-x86_64-unknown-linux-gnu/prismpm"
test -x "$prior"
prior_binary_sha=$(sha256sum "$prior" | cut -d' ' -f1)

"$prior" --project "$root" check --json >"$work/prior.json"
cargo run --locked --offline --quiet --package prismpm -- \
  --project "$root" check --json >"$work/current.json"

node - "$work/prior.json" "$work/current.json" "$root/target/bootstrap-evidence.json" \
  "$archive_sha" "$prior_binary_sha" "$source_commit" <<'NODE'
const [priorPath, currentPath, evidencePath, archiveSha, binarySha, sourceCommit] = process.argv.slice(2);
const { readFileSync, mkdirSync, writeFileSync } = require('node:fs');
const { dirname } = require('node:path');
const { createHash } = require('node:crypto');
const priorBytes = readFileSync(priorPath);
const currentBytes = readFileSync(currentPath);
const prior = JSON.parse(priorBytes);
const current = JSON.parse(currentBytes);
for (const field of ['entity_count', 'semantic_id', 'snapshot_id']) {
  if (prior[field] !== current[field]) throw new Error(`bootstrap/current ${field} differs`);
}
if (prior.schema !== 'prismpm/check-result/1' || current.schema !== prior.schema) {
  throw new Error('bootstrap/current result schema differs');
}
const sha = bytes => `sha256:${createHash('sha256').update(bytes).digest('hex')}`;
const evidence = {
  bootstrap: {
    archive_digest: `sha256:${archiveSha}`,
    binary_digest: `sha256:${binarySha}`,
    source_commit: sourceCommit,
    version: '0.2.0'
  },
  current_result_digest: sha(currentBytes),
  prior_result_digest: sha(priorBytes),
  schema: 'prismpm/bootstrap-evidence/1',
  shared_identity: {
    entity_count: current.entity_count,
    semantic_id: current.semantic_id,
    snapshot_id: current.snapshot_id
  },
  status: 'passed'
};
mkdirSync(dirname(evidencePath), { recursive: true });
writeFileSync(evidencePath, JSON.stringify(evidence));
NODE

# Validate the emitted bytes through PrismPM's registered contract rather than
# treating JSON parsing in this wrapper as conformance.
cargo run --locked --offline --quiet --package xtask -- \
  validate-contract prismpm/bootstrap-evidence/1 \
  "$root/target/bootstrap-evidence.json"

printf 'bootstrap SDK 0.2.0 verified current semantic identity %s\n' \
  "$(node -p "require('$work/current.json').semantic_id")"
