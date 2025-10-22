#!/usr/bin/env bash
# Универсальный раннер Godot: игнорирует только "Program crashed with signal 11" по тексту лога.
# Любые другие ошибки/коды возврата пробрасывает как есть.

set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
LOG_FILE="$(mktemp -t godot_run_XXXXXX.log)"

# Запускаем Godot, пишем stdout+stderr в лог и на консоль.
# ВАЖНО: берём код возврата именно godot, а не tee.
set +e
"$GODOT_BIN" "$@" |& tee "$LOG_FILE"
EXIT_CODE=${PIPESTATUS[0]}
set -e

# Если упали, но в логе есть "signal 11" — игнорируем.
if [ "$EXIT_CODE" -ne 0 ] && grep -q -E 'Program crashed with signal[[:space:]]+11' "$LOG_FILE"; then
  echo "[run_godot_safe] Detected: Program crashed with signal 11. Ignoring and returning 0."
  exit 0
fi

exit "$EXIT_CODE"
