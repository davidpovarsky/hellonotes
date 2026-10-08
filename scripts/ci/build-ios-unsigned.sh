#!/bin/bash

set -Eeuo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PROJECT="${PROJECT:-HelloNotes.xcodeproj}"
SCHEME="${SCHEME:-HelloNotes}"
CONFIGURATION="${CONFIGURATION:-Release}"
APP_NAME="${APP_NAME:-HelloNotes}"
BUILD_ROOT="${PLATFORM_BUILD_ROOT:-${ROOT_DIR}/build/ci/ios}"
DERIVED_DATA="${BUILD_ROOT}/DerivedData"
ARCHIVE_PATH="${BUILD_ROOT}/${APP_NAME}-iOS.xcarchive"
RESULT_BUNDLE="${BUILD_ROOT}/${APP_NAME}-iOS.xcresult"
LOG_DIR="${BUILD_ROOT}/logs"
ARTIFACT_DIR="${BUILD_ROOT}/artifacts"
PACKAGE_DIR="${BUILD_ROOT}/package"
SPM_CLONE_DIR="${SPM_CLONE_DIR:-${ROOT_DIR}/build/ci/SourcePackages}"
BUILD_LOG="${LOG_DIR}/xcodebuild-ios.log"
SETTINGS_LOG="${LOG_DIR}/build-settings-ios.log"
TIMING_LOG="${LOG_DIR}/build-timing-ios.log"

rm -rf "${DERIVED_DATA}" "${ARCHIVE_PATH}" "${RESULT_BUNDLE}" "${ARTIFACT_DIR}" "${PACKAGE_DIR}"
mkdir -p "${DERIVED_DATA}" "${LOG_DIR}" "${ARTIFACT_DIR}" "${PACKAGE_DIR}/Payload"

{
  echo "Project: ${ROOT_DIR}/${PROJECT}"
  echo "Scheme: ${SCHEME}"
  echo "Configuration: ${CONFIGURATION}"
  echo "SDK: iphoneos"
  echo "Destination: generic/platform=iOS"
  echo "Archive: ${ARCHIVE_PATH}"
  echo "DerivedData: ${DERIVED_DATA}"
} | tee "${LOG_DIR}/ios-build-plan.log"

xcodebuild \
  -project "${ROOT_DIR}/${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
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
    -sdk iphoneos \
    -destination "generic/platform=iOS" \
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
  echo "error: iOS archive failed with status ${build_status}." >&2
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

/usr/bin/ditto "${APP_PATH}" "${PACKAGE_DIR}/Payload/${APP_NAME}.app"
IPA_PATH="${ARTIFACT_DIR}/${APP_NAME}-unsigned.ipa"
(
  cd "${PACKAGE_DIR}"
  /usr/bin/zip -qry "${IPA_PATH}" Payload
)

if [[ ! -s "${IPA_PATH}" ]]; then
  echo "error: IPA packaging produced no file or an empty file." >&2
  exit 4
fi

ARCHIVE_ZIP="${ARTIFACT_DIR}/${APP_NAME}-unsigned.xcarchive.zip"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "${ARCHIVE_PATH}" "${ARCHIVE_ZIP}"

SYMBOLS_DIR="${BUILD_ROOT}/symbols"
mkdir -p "${SYMBOLS_DIR}"
if [[ -d "${ARCHIVE_PATH}/dSYMs" ]]; then
  /usr/bin/ditto "${ARCHIVE_PATH}/dSYMs" "${SYMBOLS_DIR}/dSYMs"
fi
if [[ -d "${ARCHIVE_PATH}/BCSymbolMaps" ]]; then
  /usr/bin/ditto "${ARCHIVE_PATH}/BCSymbolMaps" "${SYMBOLS_DIR}/BCSymbolMaps"
fi

SYMBOLS_ZIP="${ARTIFACT_DIR}/${APP_NAME}-iOS-symbols.zip"
if find "${SYMBOLS_DIR}" -mindepth 1 -print -quit | grep -q .; then
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent "${SYMBOLS_DIR}" "${SYMBOLS_ZIP}"
else
  echo "No dSYM or BCSymbolMaps were produced." > "${ARTIFACT_DIR}/${APP_NAME}-iOS-symbols-not-produced.txt"
fi

/usr/bin/shasum -a 256 "${IPA_PATH}" "${ARCHIVE_ZIP}" "${ARTIFACT_DIR}"/*.zip \
  2>/dev/null | /usr/bin/sort -u > "${ARTIFACT_DIR}/SHA256SUMS.txt"
/usr/bin/unzip -l "${IPA_PATH}" > "${LOG_DIR}/ipa-contents.txt"
/usr/bin/plutil -p "${APP_PATH}/Info.plist" > "${LOG_DIR}/built-info-plist.txt" 2>&1 || true
/usr/bin/codesign -dvvv "${APP_PATH}" > "${LOG_DIR}/codesign-state.txt" 2>&1 || true

if [[ -d "${ARCHIVE_PATH}/dSYMs/${APP_NAME}.app.dSYM" ]]; then
  xcrun dwarfdump --uuid "${ARCHIVE_PATH}/dSYMs/${APP_NAME}.app.dSYM" \
    > "${ARTIFACT_DIR}/${APP_NAME}-iOS-dsym-uuids.txt" 2>&1 || true
fi

bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${APP_PATH}/Info.plist" 2>/dev/null || true)"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${APP_PATH}/Info.plist" 2>/dev/null || true)"
build_number="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "${APP_PATH}/Info.plist" 2>/dev/null || true)"
ipa_sha="$(/usr/bin/shasum -a 256 "${IPA_PATH}" | /usr/bin/awk '{print $1}')"

cat > "${ARTIFACT_DIR}/build-manifest.json" <<JSON
{
  "product": "${APP_NAME}",
  "platform": "iOS",
  "signed": false,
  "bundleIdentifier": "${bundle_id}",
  "version": "${version}",
  "buildNumber": "${build_number}",
  "gitCommit": "${GITHUB_SHA:-unknown}",
  "gitRef": "${GITHUB_REF:-unknown}",
  "xcodeVersion": "$(xcodebuild -version | tr '\n' ' ' | sed 's/"/\\"/g')",
  "ipaFile": "$(basename "${IPA_PATH}")",
  "ipaSHA256": "${ipa_sha}",
  "elapsedSeconds": $((end_epoch - start_epoch))
}
JSON

cat > "${ARTIFACT_DIR}/build-output.txt" <<EOF_OUTPUT
IPA_PATH=${IPA_PATH}
XCARCHIVE_ZIP=${ARCHIVE_ZIP}
APP_PATH=${APP_PATH}
IPA_SHA256=${ipa_sha}
BUNDLE_IDENTIFIER=${bundle_id}
VERSION=${version}
BUILD_NUMBER=${build_number}
ELAPSED_SECONDS=$((end_epoch - start_epoch))
EOF_OUTPUT

echo "Unsigned IPA created: ${IPA_PATH}"
cat "${ARTIFACT_DIR}/SHA256SUMS.txt"
