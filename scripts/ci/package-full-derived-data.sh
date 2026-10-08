#!/bin/bash

set -Eeuo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PLATFORM="${PLATFORM:-unknown}"
BUILD_ROOT="${PLATFORM_BUILD_ROOT:-${ROOT_DIR}/build/ci/${PLATFORM}}"
DERIVED_DATA="${BUILD_ROOT}/DerivedData"
OUTPUT="${BUILD_ROOT}/DerivedData-failure.tar.gz"

if [[ ! -d "${DERIVED_DATA}" ]]; then
  echo "DerivedData does not exist; nothing to package."
  exit 0
fi

rm -f "${OUTPUT}"
/usr/bin/tar -czf "${OUTPUT}" -C "${BUILD_ROOT}" DerivedData
/usr/bin/du -h "${OUTPUT}"
