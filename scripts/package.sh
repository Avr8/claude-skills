#!/usr/bin/env bash
# Build one upload-ready zip per skill (for Claude.ai: Settings → Capabilities → Skills).
# Usage: scripts/package.sh [out-dir]   (default: dist/)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:-dist}"; mkdir -p "$OUT"; OUT="$(cd "$OUT" && pwd)"
for d in skills/*/; do
  n="$(basename "$d")"
  rm -f "$OUT/$n.zip"
  (cd skills && zip -qr "$OUT/$n.zip" "$n" -x "$n/evals/*" "*.DS_Store")
  echo "$OUT/$n.zip"
done
