#!/bin/bash

set -Eeuo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PROJECT="${PROJECT:-HelloNotes.xcodeproj}"
SCHEME="${SCHEME:-HelloNotes}"
CONFIGURATION="${CONFIGURATION:-Release}"
APP_NAME="${APP_NAME:-HelloNotes}"
BUILD_ROOT="${PLATFORM_BUILD_ROOT:-${ROOT_DIR}/build/ci/macos}"
DERIVED_DATA="${BUILD_ROOT}/DerivedData"
ARCHIVE_PATH="${BUILD_ROOT}/${APP_NAME}-macOS.xcarchive"
RESULT_BUNDLE="${BUILD_ROOT}/${APP_NAME}-macOS.xcresult"
LOG_DIR="${BUILD_ROOT}/logs"
ARTIFACT_DIR="${BUILD_ROOT}/artifacts"
SPM_CLONE_DIR="${SPM_CLONE_DIR:-${ROOT_DIR}/build/ci/SourcePackages}"
BUILD_LOG="${LOG_DIR}/xcodebuild-macos.log"
SETTINGS_LOG="${LOG_DIR}/build-settings-macos.log"
TIMING_LOG="${LOG_DIR}/build-timing-macos.log"

rm -rf "${DERIVED_DATA}" "${ARCHIVE_PATH}" "${RESULT_BUNDLE}" "${ARTIFACT_DIR}"
mkdir -p "${DERIVED_DATA}" "${LOG_DIR}" "${ARTIFACT_DIR}"

xcodebuild \
  -project "${ROOT_DIR}/${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -sdk macosx \
  -destination "generic/platform=macOS" \
  -clonedSourcePackagesDirPath "${SPM_CLONE_DIR}" \
  -showBuildSettings \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  'CODE_SIGN_IDENTITY=' \
  'DEVELOPMENT_TEAM=' \
  > "${SETTINGS_LOG}" 2>&1

start_epoch="$(date +%s)"
set +e
/usr/bin/time -lp sh -c '
  NSUnbufferedIO=YES xcodebuild \
    -project "$1" \
    -scheme "$2" \
    -configuration "$3" \
    -sdk macosx \
    -destination "generic/platform=macOS" \
    -archivePath "$4" \
    -derivedDataPath "$5" \
    -clonedSourcePackagesDirPath "$6" \
    -resultBundlePath "$7" \
    -showBuildTimingSummary \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    "CODE_SIGN_IDENTITY=" \
    "DEVELOPMENT_TEAM=" \
    COMPILER_INDEX_STORE_ENABLE=NO \
    SKIP_INSTALL=NO \
    archive
' sh \
  "${ROOT_DIR}/${PROJECT}" \
  "${SCHEME}" \
  "${CONFIGURATION}" \
  "${ARCHIVE_PATH}" \
  "${DERIVED_DATA}" \
  "${SPM_CLONE_DIR}" \
  "${RESULT_BUNDLE}" \
  2> >(tee "${TIMING_LOG}" >&2) \
  | tee "${BUILD_LOG}"
build_status=${PIPESTATUS[0]}
set -e
end_epoch="$(date +%s)"
echo "$((end_epoch - start_epoch))" > "${LOG_DIR}/elapsed-seconds.txt"

if [[ ${build_status} -ne 0 ]]; then
  echo "error: macOS archive failed with status ${build_status}." >&2
  exit "${build_status}"
fi

APP_PATH="${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app"
if [[ ! -d "${APP_PATH}" ]]; then
  APP_PATH="$(find "${ARCHIVE_PATH}" -type d -name "${APP_NAME}.app" -print -quit 2>/dev/null || true)"
fi
if [[ -z "${APP_PATH}" || ! -d "${APP_PATH}" ]]; then
  echo "error: Archive succeeded, but ${APP_NAME}.app was not found." >&2
  exit 3
fi

APP_ZIP="${ARTIFACT_DIR}/${APP_NAME}-macOS-unsigned.app.zip"
ARCHIVE_ZIP="${ARTIFACT_DIR}/${APP_NAME}-macOS-unsigned.xcarchive.zip"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "${APP_PATH}" "${APP_ZIP}"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "${ARCHIVE_PATH}" "${ARCHIVE_ZIP}"

if [[ -d "${ARCHIVE_PATH}/dSYMs" ]]; then
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent \
    "${ARCHIVE_PATH}/dSYMs" "${ARTIFACT_DIR}/${APP_NAME}-macOS-symbols.zip"
fi

/usr/bin/shasum -a 256 "${ARTIFACT_DIR}"/*.zip > "${ARTIFACT_DIR}/SHA256SUMS.txt"
/usr/bin/plutil -p "${APP_PATH}/Contents/Info.plist" > "${LOG_DIR}/built-info-plist.txt" 2>&1 || true
/usr/bin/codesign -dvvv "${APP_PATH}" > "${LOG_DIR}/codesign-state.txt" 2>&1 || true

if [[ -d "${ARCHIVE_PATH}/dSYMs/${APP_NAME}.app.dSYM" ]]; then
  xcrun dwarfdump --uuid "${ARCHIVE_PATH}/dSYMs/${APP_NAME}.app.dSYM" \
    > "${ARTIFACT_DIR}/${APP_NAME}-macOS-dsym-uuids.txt" 2>&1 || true
fi

bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${APP_PATH}/Contents/Info.plist" 2>/dev/null || true)"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${APP_PATH}/Contents/Info.plist" 2>/dev/null || true)"
build_number="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "${APP_PATH}/Contents/Info.plist" 2>/dev/null || true)"

cat > "${ARTIFACT_DIR}/build-manifest.json" <<JSON
{
  "product": "${APP_NAME}",
  "platform": "macOS",
  "signed": false,
  "bundleIdentifier": "${bundle_id}",
  "version": "${version}",
  "buildNumber": "${build_number}",
  "gitCommit": "${GITHUB_SHA:-unknown}",
  "gitRef": "${GITHUB_REF:-unknown}",
  "xcodeVersion": "$(xcodebuild -version | tr '\n' ' ' | sed 's/"/\\"/g')",
  "appArchive": "$(basename "${APP_ZIP}")",
  "xcarchive": "$(basename "${ARCHIVE_ZIP}")",
  "elapsedSeconds": $((end_epoch - start_epoch))
}
JSON

cat > "${ARTIFACT_DIR}/build-output.txt" <<EOF_OUTPUT
APP_ZIP=${APP_ZIP}
XCARCHIVE_ZIP=${ARCHIVE_ZIP}
APP_PATH=${APP_PATH}
BUNDLE_IDENTIFIER=${bundle_id}
VERSION=${version}
BUILD_NUMBER=${build_number}
ELAPSED_SECONDS=$((end_epoch - start_epoch))
EOF_OUTPUT

echo "Unsigned macOS app created: ${APP_ZIP}"
cat "${ARTIFACT_DIR}/SHA256SUMS.txt"
