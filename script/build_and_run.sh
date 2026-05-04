#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

configuration=Debug
mode=run
app_name=Squirrel
bundle_id=im.rime.inputmethod.Squirrel

for arg in "$@"; do
  case "$arg" in
    --release)
      configuration=Release
      ;;
    --debug)
      mode=debug
      ;;
    --logs)
      mode=logs
      ;;
    --telemetry)
      mode=telemetry
      ;;
    --verify)
      mode=verify
      ;;
    *)
      echo "usage: $0 [--release] [--debug|--logs|--telemetry|--verify]" >&2
      exit 64
      ;;
  esac
done

if [[ "$configuration" == "Release" ]]; then
  make -C squirrel ARCHS='arm64' release
else
  make -C squirrel ARCHS='arm64' debug
fi

app="squirrel/build/Build/Products/${configuration}/Squirrel.app"
binary="$app/Contents/MacOS/Squirrel"

pkill -x "$app_name" >/dev/null 2>&1 || true

open_app() {
  /usr/bin/open -n "$app"
}

case "$mode" in
  run)
    open_app
    ;;
  debug)
    lldb -- "$binary"
    ;;
  logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$app_name\""
    ;;
  telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$bundle_id\""
    ;;
  verify)
    open_app
    sleep 2
    pgrep -x "$app_name" >/dev/null
    ;;
esac
