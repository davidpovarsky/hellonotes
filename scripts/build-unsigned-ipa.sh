#!/bin/bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="${PROJECT_NAME:-HelloNotes.xcodeproj}"
SCHEME="${SCHEME:-HelloNotes}"
CONFIGURATION="${CONFIGURATION:-Release}"
APP_NAME="${APP_NAME:-HelloNotes}"
BUILD_ROOT="${BUILD_ROOT:-${ROOT_DIR}/build/unsigned-ipa}"
DERIVED_DATA="${DERIVED_DATA:-${BUILD_ROOT}/DerivedData}"
LOG_DIR="${LOG_DIR:-${BUILD_ROOT}/logs}"
ARTIFACT_DIR="${ARTIFACT_DIR:-${BUILD_ROOT}/artifacts}"
PACKAGE_DIR="${BUILD_ROOT}/package"
RESULT_BUNDLE="${BUILD_ROOT}/${APP_NAME}.xcresult"
SCRIPT_LOG="${LOG_DIR}/script.log"
RESOLVE_LOG="${LOG_DIR}/package-resolution.log"
BUILD_LOG="${LOG_DIR}/xcodebuild.log"
DIAGNOSTICS_LOG="${LOG_DIR}/diagnostics.log"
BUILD_SETTINGS_LOG="${LOG_DIR}/build-settings.log"

mkdir -p "${LOG_DIR}"
exec > >(tee -a "${SCRIPT_LOG}") 2>&1

on_exit() {
  local status=$?
  trap - EXIT
  set +e

  {
    echo "============================================================"
    echo "HelloNotes unsigned IPA build diagnostics"
    echo "============================================================"
    echo "Exit status: ${status}"
    echo "Finished at: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "Repository root: ${ROOT_DIR}"
    echo "Build root: ${BUILD_ROOT}"
    echo "Derived data: ${DERIVED_DATA}"
    echo
    echo "--- System ---"
    uname -a
    sw_vers
    echo
    echo "--- Selected developer directory ---"
    xcode-select -p
    echo
    echo "--- Xcode ---"
    xcodebuild -version
    echo
    echo "--- Swift ---"
    xcrun swift --version
    echo
    echo "--- Disk usage ---"
    df -h
    echo
    echo "--- Build outputs ---"
    find "${BUILD_ROOT}" -maxdepth 5 -print 2>/dev/null | sort
    echo
    echo "--- App signing state ---"
    if [[ -d "${DERIVED_DATA}/Build/Products/${CONFIGURATION}-iphoneos/${APP_NAME}.app" ]]; then
      codesign -dvvv "${DERIVED_DATA}/Build/Products/${CONFIGURATION}-iphoneos/${APP_NAME}.app" 2>&1
    else
      echo "Expected app bundle was not found."
    fi
  } >> "${DIAGNOSTICS_LOG}" 2>&1

  if [[ -d "${RESULT_BUNDLE}" ]]; then
    xcrun xcresulttool get --legacy --path "${RESULT_BUNDLE}" --format json \
      > "${LOG_DIR}/xcresult.json" 2> "${LOG_DIR}/xcresulttool-error.log" || true
  fi

  exit "${status}"
}
trap on_exit EXIT

rm -rf "${DERIVED_DATA}" "${ARTIFACT_DIR}" "${PACKAGE_DIR}" "${RESULT_BUNDLE}"
mkdir -p "${DERIVED_DATA}" "${ARTIFACT_DIR}" "${PACKAGE_DIR}"

PROJECT_PATH="${ROOT_DIR}/${PROJECT_NAME}"
if [[ ! -d "${PROJECT_PATH}" ]]; then
  echo "error: Xcode project not found at ${PROJECT_PATH}" >&2
  exit 2
fi

echo "============================================================"
echo "Building unsigned HelloNotes IPA"
echo "============================================================"
echo "Started at: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "Project: ${PROJECT_PATH}"
echo "Scheme: ${SCHEME}"
echo "Configuration: ${CONFIGURATION}"
echo "Build root: ${BUILD_ROOT}"
echo "Developer directory: $(xcode-select -p)"
xcodebuild -version

echo
echo "Listing project schemes and targets..."
xcodebuild -project "${PROJECT_PATH}" -list -json \
  2>&1 | tee "${LOG_DIR}/project-list.log"

echo
echo "Capturing iOS build settings..."
xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -showBuildSettings \
  2>&1 | tee "${BUILD_SETTINGS_LOG}"

echo
echo "Resolving Swift package dependencies..."
set +e
xcodebuild \
  -resolvePackageDependencies \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -clonedSourcePackagesDirPath "${DERIVED_DATA}/SourcePackages" \
  2>&1 | tee "${RESOLVE_LOG}"
resolve_status=${PIPESTATUS[0]}
set -e
if [[ ${resolve_status} -ne 0 ]]; then
  echo "error: Swift package resolution failed with status ${resolve_status}." >&2
  exit "${resolve_status}"
fi

echo
echo "Compiling the unsigned iOS app..."
set +e
NSUnbufferedIO=YES xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -derivedDataPath "${DERIVED_DATA}" \
  -clonedSourcePackagesDirPath "${DERIVED_DATA}/SourcePackages" \
  -resultBundlePath "${RESULT_BUNDLE}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  'CODE_SIGN_IDENTITY=' \
  'DEVELOPMENT_TEAM=' \
  COMPILER_INDEX_STORE_ENABLE=NO \
  clean build \
  2>&1 | tee "${BUILD_LOG}"
build_status=${PIPESTATUS[0]}
set -e
if [[ ${build_status} -ne 0 ]]; then
  echo "error: xcodebuild failed with status ${build_status}." >&2
  exit "${build_status}"
fi

APP_PATH="${DERIVED_DATA}/Build/Products/${CONFIGURATION}-iphoneos/${APP_NAME}.app"
if [[ ! -d "${APP_PATH}" ]]; then
  APP_PATH="$(find "${DERIVED_DATA}/Build/Products" -type d -name "${APP_NAME}.app" -path '*-iphoneos/*' -print -quit 2>/dev/null || true)"
fi

if [[ -z "${APP_PATH}" || ! -d "${APP_PATH}" ]]; then
  echo "error: Build succeeded, but ${APP_NAME}.app was not found." >&2
  exit 3
fi

echo "Built app: ${APP_PATH}"

PAYLOAD_DIR="${PACKAGE_DIR}/Payload"
mkdir -p "${PAYLOAD_DIR}"
ditto "${APP_PATH}" "${PAYLOAD_DIR}/${APP_NAME}.app"

IPA_PATH="${ARTIFACT_DIR}/${APP_NAME}-unsigned.ipa"
(
  cd "${PACKAGE_DIR}"
  /usr/bin/zip -qry "${IPA_PATH}" Payload
)

if [[ ! -s "${IPA_PATH}" ]]; then
  echo "error: IPA packaging failed or produced an empty file." >&2
  exit 4
fi

shasum -a 256 "${IPA_PATH}" > "${IPA_PATH}.sha256"
/usr/bin/du -h "${IPA_PATH}"
cat "${IPA_PATH}.sha256"

plutil -p "${APP_PATH}/Info.plist" > "${LOG_DIR}/built-info-plist.txt" 2>&1 || true
codesign -dvvv "${APP_PATH}" > "${LOG_DIR}/codesign-state.txt" 2>&1 || true

{
  echo "IPA_PATH=${IPA_PATH}"
  echo "APP_PATH=${APP_PATH}"
  echo "SHA256=$(awk '{print $1}' "${IPA_PATH}.sha256")"
} > "${ARTIFACT_DIR}/build-output.txt"

echo
echo "Unsigned IPA created successfully: ${IPA_PATH}"
