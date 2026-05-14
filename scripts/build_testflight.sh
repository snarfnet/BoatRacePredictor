#!/usr/bin/env bash
set -euo pipefail

APP_VERSION="${APP_VERSION:-0.1}"
BUILD_NUMBER="${BUILD_NUMBER:-$(date +%Y%m%d%H%M)}"
PROJECT_NAME="BoatRacePredictor"
SCHEME="BoatRacePredictor"
ARCHIVE_PATH="build/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="build/export"
IPA_PATH="${EXPORT_PATH}/${PROJECT_NAME}.ipa"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is not installed. Run: brew install xcodegen"
  exit 1
fi

if [[ -z "${ASC_KEY_ID:-}" || -z "${ASC_ISSUER_ID:-}" ]]; then
  echo "Set ASC_KEY_ID and ASC_ISSUER_ID before upload."
  echo "The key file should be at ~/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID:-YOUR_KEY_ID}.p8"
  exit 1
fi

rm -rf build
xcodegen generate

xcodebuild \
  -project "${PROJECT_NAME}.xcodeproj" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "${ARCHIVE_PATH}" \
  MARKETING_VERSION="${APP_VERSION}" \
  CURRENT_PROJECT_VERSION="${BUILD_NUMBER}" \
  clean archive

xcodebuild -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath "${EXPORT_PATH}"

xcrun altool --upload-app \
  --type ios \
  --file "${IPA_PATH}" \
  --apiKey "${ASC_KEY_ID}" \
  --apiIssuer "${ASC_ISSUER_ID}"

echo "Uploaded build ${BUILD_NUMBER} for version ${APP_VERSION} to App Store Connect."
