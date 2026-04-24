#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")/.."

configuration=Debug
verify=0

for arg in "$@"; do
  case "$arg" in
    --release)
      configuration=Release
      ;;
    --verify)
      verify=1
      ;;
    *)
      echo "unknown argument: $arg" >&2
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

if pgrep -x Squirrel >/dev/null 2>&1; then
  killall Squirrel || true
fi

/usr/bin/open -n "$app"

if [[ "$verify" -eq 1 ]]; then
  sleep 2
  pgrep -x Squirrel >/dev/null
fi
