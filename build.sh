#!/usr/bin/env bash
# Build the installable .plasmoid (a plain zip of the package/ directory).
set -euo pipefail
cd "$(dirname "$0")"

VERSION=$(grep -oE '"Version"[[:space:]]*:[[:space:]]*"[^"]+"' package/metadata.json \
          | grep -oE '[0-9]+(\.[0-9]+)*' | head -1)
OUT="claude-quota-${VERSION:-dev}.plasmoid"

STABLE="claude-quota.plasmoid"   # version-less name for a permanent download URL

rm -f "$OUT" "$STABLE"
( cd package && zip -r -q "../$OUT" metadata.json contents )
cp -f "$OUT" "$STABLE"
echo "Built $OUT  (+ stable copy $STABLE)"
