#!/bin/bash

set -Eeuo pipefail

XCODE_VERSION="${XCODE_VERSION:-26.5}"
BUILD_ROOT="${BUILD_ROOT:-${GITHUB_WORKSPACE:-$(pwd)}/build/ci}"
ENV_LOG="${BUILD_ROOT}/runner-environment.log"
mkdir -p "${BUILD_ROOT}"

{
  echo "============================================================"
  echo "HelloNotes runner environment"
  echo "============================================================"
  echo "UTC time: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "Runner name: ${RUNNER_NAME:-unknown}"
  echo "Runner OS: ${RUNNER_OS:-unknown}"
  echo "Runner architecture: ${RUNNER_ARCH:-unknown}"
  uname -a
  sw_vers
  echo
  echo "Installed Xcode applications:"
  /bin/ls -1d /Applications/Xcode*.app 2>/dev/null || true
} | tee "${ENV_LOG}"

candidates=(
  "/Applications/Xcode_${XCODE_VERSION}.app"
  "/Applications/Xcode_${XCODE_VERSION}.0.app"
)

XCODE_APP=""
for candidate in "${candidates[@]}"; do
  if [[ -d "${candidate}" ]]; then
    XCODE_APP="${candidate}"
    break
  fi
done

if [[ -z "${XCODE_APP}" ]]; then
  XCODE_APP="$(/bin/ls -1d /Applications/Xcode_${XCODE_VERSION}*.app 2>/dev/null | /usr/bin/head -n 1 || true)"
fi

if [[ -z "${XCODE_APP}" || ! -d "${XCODE_APP}" ]]; then
  echo "error: Xcode ${XCODE_VERSION} was not found on this runner." | tee -a "${ENV_LOG}" >&2
  exit 1
fi

DEVELOPER_DIR_VALUE="${XCODE_APP}/Contents/Developer"
export DEVELOPER_DIR="${DEVELOPER_DIR_VALUE}"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "DEVELOPER_DIR=${DEVELOPER_DIR_VALUE}" >> "${GITHUB_ENV}"
  echo "SELECTED_XCODE_APP=${XCODE_APP}" >> "${GITHUB_ENV}"
fi

{
  echo
  echo "Selected Xcode application: ${XCODE_APP}"
  echo "DEVELOPER_DIR: ${DEVELOPER_DIR_VALUE}"
  xcodebuild -version
  echo
  echo "Installed SDKs:"
  xcodebuild -showsdks
  echo
  echo "Selected iOS SDK: $(xcrun --sdk iphoneos --show-sdk-version)"
  echo "Selected macOS SDK: $(xcrun --sdk macosx --show-sdk-version)"
  echo
  echo "Swift:"
  xcrun swift --version
} | tee -a "${ENV_LOG}"

selected_version="$(xcodebuild -version | /usr/bin/head -n 1 | /usr/bin/awk '{print $2}')"
if [[ "${selected_version}" != "${XCODE_VERSION}"* ]]; then
  echo "error: Requested Xcode ${XCODE_VERSION}, but selected ${selected_version}." | tee -a "${ENV_LOG}" >&2
  exit 1
fi
