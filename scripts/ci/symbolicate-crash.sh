#!/bin/bash

set -Eeuo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/ci/symbolicate-crash.sh <crash-report> <app-dsym> [output-file]

Example:
  scripts/ci/symbolicate-crash.sh crash.ips HelloNotes.app.dSYM symbolicated.txt

This helper uses the symbolicatecrash tool bundled inside the selected Xcode.
The dSYM must match the UUID in the crash report.
USAGE
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 2
fi

CRASH_REPORT="$1"
DSYM_PATH="$2"
OUTPUT_FILE="${3:-symbolicated-crash.txt}"

if [[ ! -f "${CRASH_REPORT}" ]]; then
  echo "Crash report not found: ${CRASH_REPORT}" >&2
  exit 2
fi
if [[ ! -d "${DSYM_PATH}" ]]; then
  echo "dSYM not found: ${DSYM_PATH}" >&2
  exit 2
fi

SYMBOLICATECRASH="$(find "${DEVELOPER_DIR:-$(xcode-select -p)}" -name symbolicatecrash -type f -print -quit 2>/dev/null || true)"
if [[ -z "${SYMBOLICATECRASH}" ]]; then
  echo "symbolicatecrash was not found in the selected Xcode." >&2
  exit 3
fi

export DEVELOPER_DIR="${DEVELOPER_DIR:-$(xcode-select -p)}"
"${SYMBOLICATECRASH}" "${CRASH_REPORT}" "${DSYM_PATH}" > "${OUTPUT_FILE}"
echo "Symbolicated crash written to: ${OUTPUT_FILE}"
