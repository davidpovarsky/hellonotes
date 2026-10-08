#!/bin/bash

set -Eeuo pipefail

ROOT_DIR="${GITHUB_WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
PLATFORM="${PLATFORM:-unknown}"
PROJECT="${PROJECT:-HelloNotes.xcodeproj}"
SCHEME="${SCHEME:-HelloNotes}"
CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_ROOT="${PLATFORM_BUILD_ROOT:-${ROOT_DIR}/build/ci/${PLATFORM}}"
LOG_DIR="${BUILD_ROOT}/logs"
DIAG_DIR="${BUILD_ROOT}/diagnostics"
DERIVED_DATA="${BUILD_ROOT}/DerivedData"
RESULT_BUNDLE=""
BUILD_OUTCOME="${BUILD_OUTCOME:-unknown}"

mkdir -p "${LOG_DIR}" "${DIAG_DIR}"

if [[ "${PLATFORM}" == "ios" ]]; then
  RESULT_BUNDLE="${BUILD_ROOT}/HelloNotes-iOS.xcresult"
  SDK="iphoneos"
  DESTINATION="generic/platform=iOS"
else
  RESULT_BUNDLE="${BUILD_ROOT}/HelloNotes-macOS.xcresult"
  SDK="macosx"
  DESTINATION="generic/platform=macOS"
fi

{
  echo "============================================================"
  echo "HelloNotes ${PLATFORM} diagnostics"
  echo "============================================================"
  echo "Build outcome: ${BUILD_OUTCOME}"
  echo "UTC time: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "Git SHA: ${GITHUB_SHA:-unknown}"
  echo "Git ref: ${GITHUB_REF:-unknown}"
  echo "Repository: ${GITHUB_REPOSITORY:-unknown}"
  echo "Run ID: ${GITHUB_RUN_ID:-unknown}"
  echo "Run attempt: ${GITHUB_RUN_ATTEMPT:-unknown}"
  echo
  echo "--- OS ---"
  uname -a
  sw_vers
  echo
  echo "--- Xcode ---"
  echo "DEVELOPER_DIR=${DEVELOPER_DIR:-unset}"
  xcodebuild -version
  xcodebuild -showsdks
  echo
  echo "--- Swift ---"
  xcrun swift --version
  echo
  echo "--- Disk ---"
  df -h
  echo
  echo "--- Git status ---"
  git -C "${ROOT_DIR}" status --short --branch || true
  echo
  echo "--- Build tree ---"
  find "${BUILD_ROOT}" -maxdepth 5 -print 2>/dev/null | sort
} > "${DIAG_DIR}/environment-and-files.txt" 2>&1

xcodebuild -project "${ROOT_DIR}/${PROJECT}" -list -json \
  > "${DIAG_DIR}/project-list.json" 2> "${DIAG_DIR}/project-list-error.log" || true

xcodebuild \
  -project "${ROOT_DIR}/${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -sdk "${SDK}" \
  -destination "${DESTINATION}" \
  -showBuildSettings \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  'CODE_SIGN_IDENTITY=' \
  'DEVELOPMENT_TEAM=' \
  > "${DIAG_DIR}/fresh-build-settings.txt" 2>&1 || true

if [[ -d "${RESULT_BUNDLE}" ]]; then
  xcrun xcresulttool get object --legacy --path "${RESULT_BUNDLE}" --format json \
    > "${DIAG_DIR}/xcresult.json" 2> "${DIAG_DIR}/xcresulttool-error.log" || \
  xcrun xcresulttool get --legacy --path "${RESULT_BUNDLE}" --format json \
    > "${DIAG_DIR}/xcresult.json" 2>> "${DIAG_DIR}/xcresulttool-error.log" || true
fi

{
  echo "Errors and warnings extracted from available logs"
  echo "=================================================="
  find "${LOG_DIR}" "${ROOT_DIR}/build/ci/package-resolution-logs" \
    -type f -name '*.log' -print0 2>/dev/null \
    | xargs -0 grep -nE -i '(^|[^a-z])(error:|fatal error:|warning:|failed|failure|timed out|timeout|could not|unable to)' \
    2>/dev/null || true
} > "${DIAG_DIR}/errors-and-warnings.txt"

if [[ -d "${DERIVED_DATA}/Logs" ]]; then
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent \
    "${DERIVED_DATA}/Logs" "${DIAG_DIR}/DerivedData-Logs.zip" || true
fi

elapsed="unknown"
if [[ -f "${LOG_DIR}/elapsed-seconds.txt" ]]; then
  elapsed="$(cat "${LOG_DIR}/elapsed-seconds.txt")"
fi

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## HelloNotes ${PLATFORM} build"
    echo
    echo "| Field | Value |"
    echo "|---|---|"
    echo "| Outcome | **${BUILD_OUTCOME}** |"
    echo "| Platform | \`${PLATFORM}\` |"
    echo "| Xcode | \`$(xcodebuild -version | head -n 1)\` |"
    echo "| SDK | \`${SDK}\` |"
    echo "| Configuration | \`${CONFIGURATION}\` |"
    echo "| Elapsed | \`${elapsed} seconds\` |"
    echo "| Commit | \`${GITHUB_SHA:-unknown}\` |"
    echo

    if [[ "${BUILD_OUTCOME}" == "success" && -d "${BUILD_ROOT}/artifacts" ]]; then
      echo "### Distribution files"
      echo
      find "${BUILD_ROOT}/artifacts" -maxdepth 1 -type f -print \
        | sort \
        | while IFS= read -r file; do
            echo "- \`$(basename "$file")\`"
          done
    else
      echo "### Diagnostic excerpt"
      echo
      echo '```text'
      tail -n 60 "${DIAG_DIR}/errors-and-warnings.txt" 2>/dev/null || true
      echo '```'
      echo
      echo "Download the \`HelloNotes-${PLATFORM}-diagnostics\` artifact for complete logs and xcresult data."
    fi
  } >> "${GITHUB_STEP_SUMMARY}"
fi
