#!/bin/bash

set -Eeuo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PROJECT="${PROJECT:-HelloNotes.xcodeproj}"
SCHEME="${SCHEME:-HelloNotes}"
BUILD_ROOT="${BUILD_ROOT:-${ROOT_DIR}/build/ci}"
SPM_CLONE_DIR="${SPM_CLONE_DIR:-${BUILD_ROOT}/SourcePackages}"
LOG_DIR="${BUILD_ROOT}/package-resolution-logs"
MAX_ATTEMPTS="${SPM_RESOLVE_ATTEMPTS:-3}"

mkdir -p "${SPM_CLONE_DIR}" "${LOG_DIR}"

status=1
attempt=1
while [[ ${attempt} -le ${MAX_ATTEMPTS} ]]; do
  log_file="${LOG_DIR}/resolve-attempt-${attempt}.log"
  echo "Resolving Swift packages (attempt ${attempt}/${MAX_ATTEMPTS})..."

  set +e
  NSUnbufferedIO=YES xcodebuild \
    -resolvePackageDependencies \
    -project "${ROOT_DIR}/${PROJECT}" \
    -scheme "${SCHEME}" \
    -clonedSourcePackagesDirPath "${SPM_CLONE_DIR}" \
    2>&1 | tee "${log_file}"
  status=${PIPESTATUS[0]}
  set -e

  if [[ ${status} -eq 0 ]]; then
    echo "Swift package resolution succeeded on attempt ${attempt}."
    break
  fi

  echo "Swift package resolution failed with status ${status}." >&2
  if [[ ${attempt} -lt ${MAX_ATTEMPTS} ]]; then
    sleep_seconds=$((attempt * 20))
    echo "Retrying in ${sleep_seconds} seconds..."
    sleep "${sleep_seconds}"
  fi
  attempt=$((attempt + 1))
done

cat "${LOG_DIR}"/resolve-attempt-*.log > "${BUILD_ROOT}/package-resolution.log" 2>/dev/null || true

if [[ ${status} -ne 0 ]]; then
  echo "error: Swift package resolution failed after ${MAX_ATTEMPTS} attempts." >&2
  exit "${status}"
fi
