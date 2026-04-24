#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQUIRREL_DIR="${ROOT_DIR}/squirrel"
RIME_ICE_DIR="${ROOT_DIR}/vendor/rime-ice"

mkdir -p "${ROOT_DIR}/vendor"

if [[ ! -d "${SQUIRREL_DIR}/.git" ]]; then
  git clone --recursive https://github.com/rime/squirrel.git "${SQUIRREL_DIR}"
else
  git -C "${SQUIRREL_DIR}" submodule update --init --recursive
fi

if [[ ! -d "${RIME_ICE_DIR}/.git" ]]; then
  git clone --depth 1 https://github.com/iDvel/rime-ice.git "${RIME_ICE_DIR}"
fi

echo "源码就绪:"
echo "- Squirrel: ${SQUIRREL_DIR}"
echo "- rime-ice: ${RIME_ICE_DIR}"
echo
echo "下一步:"
echo "  1) make -C squirrel debug ARCHS='arm64'"
echo "  2) make -C squirrel package ARCHS='arm64 x86_64' BUILD_UNIVERSAL=1"
