#!/bin/sh
# SPDX-License-Identifier: MIT
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${BIN:-$(mktemp -d)}"
CXX="${CXX:-c++}"
build() { "$CXX" -std=c++17 -Wall -Werror -Wno-unused-function -O2 -I "$1" -I "$ROOT" -o "$BIN/$2" "$ROOT/tests/morton_check.cpp"; }
must_fail() {
  rc=0; "$BIN/$1" "$2" > "$BIN/$1.out" || rc=$?
  cat "$BIN/$1.out"
  if [ "$rc" != 1 ] || ! grep -q '^RESULT: FAIL$' "$BIN/$1.out"; then echo "RESULT: ERROR the control $1 was not caught"; exit 2; fi
}
if grep -n -i hilbert "$ROOT/predictive_bvh.h"; then echo "RESULT: FAIL the header names the old curve"; exit 1; fi
mkdir -p "$BIN/h-swapped" "$BIN/h-skewed"
sed 's/(pbvh_part1by2(x) << 2) | (pbvh_part1by2(y) << 1) | pbvh_part1by2(z)/(pbvh_part1by2(z) << 2) | (pbvh_part1by2(y) << 1) | pbvh_part1by2(x)/' "$ROOT/predictive_bvh.h" > "$BIN/h-swapped/predictive_bvh.h"
sed 's/int64_t cell = (int64_t)1 << shift;/int64_t cell = (int64_t)2 << shift;/' "$ROOT/predictive_bvh.h" > "$BIN/h-skewed/predictive_bvh.h"
if cmp -s "$ROOT/predictive_bvh.h" "$BIN/h-swapped/predictive_bvh.h" || cmp -s "$ROOT/predictive_bvh.h" "$BIN/h-skewed/predictive_bvh.h"; then echo "RESULT: ERROR a control was not planted"; exit 2; fi
awk 'BEGIN{FS=OFS="\t"} NR==200{$4=$4+1} {print}' "$ROOT/testdata/morton_golden.tsv" > "$BIN/altered.tsv"
build "$ROOT" real
build "$BIN/h-swapped" swapped
build "$BIN/h-skewed" skewed
must_fail swapped "$ROOT/testdata/morton_golden.tsv"
must_fail skewed "$ROOT/testdata/morton_golden.tsv"
must_fail real "$BIN/altered.tsv"
"$BIN/real" "$ROOT/testdata/morton_golden.tsv"
