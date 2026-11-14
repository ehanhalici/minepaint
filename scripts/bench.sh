#!/usr/bin/env bash
# Sik cizim yolunda CPU maliyeti olcumu (Xvfb + xdotool). Kullanim: scripts/bench.sh IKILI [IKILI2 ...]
# Her ikili icin: bosta CPU (3 sn) ve sabit bir darbe dizisi sirasinda CPU (cizim - bosta) tik sayisi yazilir.
# Gercek ekrana dokunmaz; kendi Xvfb ekranini acar. nix-shell -p xvfb xdotool gerekir.
set -u
DISP=":97"
STROKES="${STROKES:-40}"
STEPS="${STEPS:-60}"

need() { command -v "$1" > /dev/null 2>&1 || { echo "eksik arac: $1 (nix-shell -p xvfb xdotool)" >&2; exit 2; }; }
need Xvfb; need xdotool

cpu_ticks() { awk '{print $14 + $15}' "/proc/$1/stat"; }

run_one() {
  local bin="$1"
  Xvfb "$DISP" -screen 0 1280x800x24 +extension GLX > /dev/null 2>&1 &
  local xp=$!
  sleep 2
  DISPLAY="$DISP" "$bin" > /dev/null 2>&1 &
  local ap=$!
  sleep 2
  local i0 i1 s0 s1
  i0=$(cpu_ticks "$ap"); sleep 3; i1=$(cpu_ticks "$ap")
  local idle=$((i1 - i0))
  s0=$(cpu_ticks "$ap")
  local t0 t1
  t0=$(date +%s.%N)
  for ((s = 0; s < STROKES; s++)); do
    local y=$((150 + (s * 10) % 500))
    DISPLAY="$DISP" xdotool mousemove 200 "$y" mousedown 1
    for ((k = 0; k < STEPS; k++)); do
      DISPLAY="$DISP" xdotool mousemove $((200 + k * 8)) $((y + (k % 7) * 3))
    done
    DISPLAY="$DISP" xdotool mouseup 1
  done
  t1=$(date +%s.%N)
  s1=$(cpu_ticks "$ap")
  local rss
  rss=$(awk '/VmRSS/ {print $2}' "/proc/$ap/status")
  local wall
  wall=$(awk -v a="$t0" -v b="$t1" 'BEGIN{printf "%.2f", b - a}')
  local per_s=$(( (s1 - s0) ))
  echo "$bin: bosta/3sn=$idle tik, cizim=$per_s tik, RSS=${rss}kB (wall ${wall}s, ${STROKES}x${STEPS} nokta)"
  kill "$ap" 2> /dev/null; kill "$xp" 2> /dev/null; wait 2> /dev/null
}

for b in "$@"; do run_one "$b"; done
