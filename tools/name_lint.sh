#!/bin/sh
# SPDX-License-Identifier: MIT
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${BIN:-$(mktemp -d)}"
OLD='[h]ilbert'
lint() { (cd "$1" && grep -r -n -i "$OLD" . --exclude-dir=.git --exclude-dir=.lake --exclude-dir=compare --exclude=morton.md --exclude=lake-manifest.json); }
mkdir -p "$BIN/planted/PredictiveBvh/core"
printf 'def %s%sOfBox := 0\n' "hil" "bert" > "$BIN/planted/PredictiveBvh/core/Planted.lean"
if ! lint "$BIN/planted" > /dev/null; then echo "RESULT: ERROR the lint did not find a planted name"; exit 2; fi
if lint "$ROOT"; then echo "RESULT: FAIL a file outside PredictiveBvh/compare names the old curve"; exit 1; fi
echo "RESULT: PASS"
