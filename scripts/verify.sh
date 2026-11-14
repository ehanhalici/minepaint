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


# .hats dosyalari tek basina da tip denetiminden gecmeli (include edenlerin ortak on ekiyle).
check_hats() {
  local h="$1" wrapper
  if head -n 5 "$h" | grep -q '^// fragment:'; then return 0; fi
  wrapper="$(mktemp --suffix=.dats)"
  {
    echo '#include "share/atspre_define.hats"'
    echo '#include "share/atspre_staload.hats"'
    echo '#include "draw_engine/minepaint_types.hats"'
    echo '#include "sys/airlock.hats"'
    echo "#include \"$ROOT/$h\""
  } > "$wrapper"
  total=$((total + 1))
  if ! patsopt -tc "${INCLUDES[@]}" -d "$wrapper" > "$TC_LOG" 2>&1; then
    fail=$((fail + 1))
    echo "FAIL $h (tek basina)"
    head -n 20 "$TC_LOG"
  fi
  rm -f "$wrapper"
}
while IFS= read -r f; do check_hats "$f"; done < <(find src -name '*.hats' | sort)

# .cats / cprelude.h: C sozdizimi (clang) denetimi.
if command -v clang > /dev/null 2>&1; then
  total=$((total + 1))
  if ! echo | clang -fsyntax-only -x c -I src -include src/sys/cprelude.h - > "$TC_LOG" 2>&1; then
    fail=$((fail + 1)); echo "FAIL src/sys/cprelude.h (C sozdizimi)"; head -n 20 "$TC_LOG"
  fi
fi

# skill.md kural kapisi (yasakli simgeler, tek assume, praxi yeri, metriksiz ozyineleme).
total=$((total + 1))
if ! python3 scripts/check_rules.py; then
  fail=$((fail + 1)); echo "FAIL kural kapisi (scripts/check_rules.py)"
fi

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
