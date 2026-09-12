#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# The external-oracle corpus must execute in the SDK image, including on the
# first clean source gate before a release image exists. Build an exact local
# image and pass its content identity to the tests; a caller may instead supply
# an already verified digest (for example, the released image in a consumer
# repository).
if test -z "${PRISMPM_TEST_SDK_IMAGE:-}"; then
  docker build \
    --build-arg SOURCE_DATE_EPOCH=0 \
    --file sdk/Dockerfile \
    --target runtime \
    --tag prismpm-vv-sdk:gate \
    .
  image_id=$(docker image inspect prismpm-vv-sdk:gate --format '{{.Id}}')
  case "$image_id" in
    sha256:????????????????????????????????????????????????????????????????) ;;
    *) printf 'SDK gate build returned an invalid image identity: %s\n' "$image_id" >&2; exit 1 ;;
  esac
  export PRISMPM_TEST_SDK_IMAGE="prismpm-vv-sdk@$image_id"
fi

exec cargo xtask vv
