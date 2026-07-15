#!/usr/bin/env bash
# Publisher: Immutable Registry Anchor
set -euo pipefail

ARTIFACT="$1"
HASH=$(sha256sum "$ARTIFACT" | awk '{print $1}')
TIMESTAMP=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

echo "{\"artifact\": \"$ARTIFACT\", \"hash\": \"$HASH\", \"timestamp\": \"$TIMESTAMP\"}" >> /home/ruth/Multiplicity/Governance/State/archivum.log
echo "[PUBLISHED] $ARTIFACT anchored with hash $HASH"
