# HelloNotes CI bundle

This bundle is intended to be copied into the root of the `davidpovarsky/hellonotes` repository.

## Files installed

- `.github/workflows/hellonotes-ci.yml`
- `scripts/ci/select-xcode.sh`
- `scripts/ci/resolve-packages.sh`
- `scripts/ci/build-ios-unsigned.sh`
- `scripts/ci/build-macos-unsigned.sh`
- `scripts/ci/collect-diagnostics.sh`
- `scripts/ci/package-full-derived-data.sh`
- `scripts/ci/symbolicate-crash.sh`

## What the workflow does

### iOS job

- Runs on GitHub's `macos-26` hosted runner.
- Selects Xcode 26.5 because the project currently targets iOS 26.5.
- Restores a Swift Package Manager cache.
- Resolves packages with up to three attempts.
- Creates an unsigned iOS `.xcarchive`.
- Packages the application as `HelloNotes-unsigned.ipa`.
- Produces SHA-256 checksums.
- Uploads dSYMs and UUID information when Xcode produces them.
- Saves the `.xcresult`, Xcode logs, build settings, timing, environment details, and extracted errors.

### macOS job

- Builds the same shared scheme for macOS without signing.
- Produces an unsigned `.app.zip` and `.xcarchive.zip`.
- Produces dSYMs and checksums when available.

### Releases

When a pushed tag starts with `v` (for example `v1.0.0`), the workflow downloads the successful distribution artifacts and publishes them as assets on a GitHub Release. If the release already exists, matching assets are replaced.

## Artifacts created after a successful run

- `HelloNotes-ios-distribution`
- `HelloNotes-macos-distribution`
- `HelloNotes-ios-diagnostics`
- `HelloNotes-macos-diagnostics`

The iOS distribution artifact contains the IPA, zipped xcarchive, checksums, build manifest, and symbols. The diagnostics artifacts are uploaded even when a build fails.

## Full DerivedData on failure

A complete DerivedData archive can be very large. It is therefore disabled by default. For a manual workflow run, enable the `upload_full_derived_data_on_failure` input. A compact DerivedData logs archive is always collected.

## Important limitation of an unsigned IPA

An unsigned IPA is a build artifact, not an App Store or ordinary device-installable package. It must be signed later with an appropriate Apple certificate and provisioning profile before normal installation on an iPhone or iPad.

## Local script use on a Mac

From the repository root:

```bash
chmod +x scripts/ci/*.sh
export XCODE_VERSION=26.5
export DEVELOPER_DIR=/Applications/Xcode_26.5.app/Contents/Developer
bash scripts/ci/resolve-packages.sh
PLATFORM_BUILD_ROOT="$PWD/build/ci/ios" bash scripts/ci/build-ios-unsigned.sh
```

The GitHub workflow does not require any Apple signing secrets because code signing is explicitly disabled.
