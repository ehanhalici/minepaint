#!/usr/bin/env bash
# Statik tip denetimi + build kapisi.
# Kullanim: scripts/verify.sh [--no-build]

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

if [ -z "${PATSHOME:-}" ]; then
  echo "HATA: PATSHOME tanimli degil (nix-shell icinde calistirin)" >&2
  exit 1
fi

INCLUDES=(-IATS src -IATS src/draw_engine -IATS "$PATSHOME" -IATS "$PATSHOME/share")
TC_LOG="$(mktemp)"
trap 'rm -f "$TC_LOG"' EXIT

fail=0
total=0

check_file() {
  local mode="$1" file="$2"
  total=$((total + 1))
  if ! patsopt -tc "${INCLUDES[@]}" "$mode" "$file" > "$TC_LOG" 2>&1; then
    fail=$((fail + 1))
    echo "FAIL $file"
    head -n 20 "$TC_LOG"
  fi
}

while IFS= read -r f; do check_file -s "$f"; done < <(find src -name '*.sats' | sort)
while IFS= read -r f; do check_file -d "$f"; done < <(find src -name '*.dats' | sort)

echo "patsopt -tc: total=$total fail=$fail"
if [ "$fail" -ne 0 ]; then
  exit 1
fi

if [ "${1:-}" = "--no-build" ]; then
  exit 0
fi

BUILD_DIR="${BUILD_DIR:-build-verify}"
cmake -S . -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Debug > /dev/null || exit 1
cmake --build "$BUILD_DIR" -j"$(nproc)" || exit 1
echo "verify: OK"
