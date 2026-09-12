#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

cargo fetch --locked
cargo fetch --locked --manifest-path vendor/lexlean/Cargo.toml

# PrismPM verifies Hologram archives with an embedded, independently locked
# Cargo harness. Fetch that graph while network access is available so the
# normative gate can build it offline from a cold devcontainer cache.
oracle_work=$(mktemp -d)
cleanup() {
  rm -rf "$oracle_work"
}
trap cleanup EXIT

mkdir -p "$oracle_work/hologram-live" "$oracle_work/harness/src"
tar -xf crates/prismpm/vendor/hologram-live.tar \
  -C "$oracle_work/hologram-live"
cp tests/hologram-oracle/Cargo.toml "$oracle_work/harness/Cargo.toml"
cp tests/hologram-oracle/Cargo.lock "$oracle_work/harness/Cargo.lock"
cp tests/hologram-oracle/src/main.rs "$oracle_work/harness/src/main.rs"
cargo fetch --locked --manifest-path "$oracle_work/harness/Cargo.toml"

cargo deny fetch

# The no-skip Distribution conformance gate runs the exact official suite
# against this immutable registry subject on an internal Docker network. Pull
# while acquisition is authorized; verification itself never reaches a public
# network.
zot_image='ghcr.io/project-zot/zot@sha256:cd2aea942f428630bcb4190542be6abd35e14177aab84fc7ccad0dca8ecb363d'
docker pull "$zot_image"
observed_zot=$(docker image inspect "$zot_image" --format '{{index .RepoDigests 0}}')
case "$observed_zot" in
  *@sha256:cd2aea942f428630bcb4190542be6abd35e14177aab84fc7ccad0dca8ecb363d) ;;
  *) printf 'Zot acquisition did not preserve the locked digest: %s\n' "$observed_zot" >&2; exit 1 ;;
esac

# The previous accepted SDK is an independent bootstrap input, not an output
# of the 0.3 build. Acquire it explicitly while networking is authorized; the
# repository gate consumes only these checksum-verified cached bytes.
bootstrap_cache="$root/.prism/cache/bootstrap"
bootstrap_archive="$bootstrap_cache/prismpm-0.2.0-x86_64-unknown-linux-gnu.tar.gz"
bootstrap_sha=f3dd999f5618db154fa06222a06f9de95d86e1dbf683954426ea91c974cbe24c
mkdir -p "$bootstrap_cache"
if [ -f "$bootstrap_archive" ]; then
  printf '%s  %s\n' "$bootstrap_sha" "$bootstrap_archive" | sha256sum --check --strict
else
  bootstrap_staging=$(mktemp "$bootstrap_cache/download.XXXXXX")
  trap 'rm -f "$bootstrap_staging"; cleanup' EXIT
  curl --fail --location --proto '=https' --tlsv1.2 --silent --show-error \
    https://github.com/UOR-Foundation/PrismPM/releases/download/v0.2.0/prismpm-0.2.0-x86_64-unknown-linux-gnu.tar.gz \
    --output "$bootstrap_staging"
  printf '%s  %s\n' "$bootstrap_sha" "$bootstrap_staging" | sha256sum --check --strict
  chmod 0444 "$bootstrap_staging"
  mv "$bootstrap_staging" "$bootstrap_archive"
fi
