#!/usr/bin/env bash
# Kullanim: compile.sh [-r | -d]   (-r: Release, -d: Debug)
# Once statik tip denetimi (verify.sh --no-build), sonra build, sonra calistirma.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

build_type_of() {
  case "${1:-}" in
    -r) echo "Release" ;;
    -d) echo "Debug" ;;
    *)
      echo "Usage: compile.sh [-r] [-d]" >&2
      echo "  -r: Release build" >&2
      echo "  -d: Debug build" >&2
      exit 1
      ;;
  esac
}

BUILD_TYPE="$(build_type_of "${1:-}")"

bash "$ROOT/scripts/verify.sh" --no-build
mkdir -p "$ROOT/build"
cd "$ROOT/build"
cmake -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ../
make
./minepaint
