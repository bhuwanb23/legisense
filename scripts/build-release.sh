#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Local Release Build Script
# Simulates the GitHub Actions release pipeline locally.
#
# Usage:
#   ./scripts/build-release.sh [tag]
#
# Examples:
#   ./scripts/build-release.sh              # Build with debug signing
#   ./scripts/build-release.sh v1.0.0       # Build with release signing
#
# Prerequisites:
#   - Flutter SDK installed
#   - Java 17+ installed
#   - Android SDK installed
#
# For release signing, set environment variables:
#   KEYSTORE_BASE64, KEY_STORE_PASSWORD, KEY_PASSWORD, KEY_ALIAS
# ============================================================

TAG="${1:-v0.0.0-dev}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APP_DIR="$PROJECT_ROOT/app"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

step() { echo -e "\n${GREEN}==>${NC} $1"; }
warn() { echo -e "${YELLOW}WARNING:${NC} $1"; }
fail() { echo -e "${RED}FAILED:${NC} $1"; exit 1; }

echo "============================================"
echo " Legisense Release Build"
echo " Tag: $TAG"
echo "============================================"

# ---- Step 1: Check prerequisites ----
step "Checking prerequisites..."
command -v flutter >/dev/null 2>&1 || fail "Flutter not found in PATH"
command -v java >/dev/null 2>&1 || fail "Java not found in PATH"

FLUTTER_VERSION=$(flutter --version | head -1)
JAVA_VERSION=$(java -version 2>&1 | head -1)
echo "  Flutter: $FLUTTER_VERSION"
echo "  Java:   $JAVA_VERSION"

# ---- Step 2: Flutter info ----
step "Flutter doctor ( abbreviated )"
flutter doctor -v 2>&1 | grep -E "Flutter|Dart|Android" | head -5

# ---- Step 3: Install dependencies ----
step "Installing Flutter dependencies..."
cd "$APP_DIR"
flutter pub get --no-pub 2>/dev/null || flutter pub get

# ---- Step 4: Decode keystore (if secrets are set) ----
KEystore_decoded=false
if [ -n "${KEYSTORE_BASE64:-}" ]; then
  step "Decoding release keystore from environment..."
  echo "$KEYSTORE_BASE64" | base64 -d > android/app/release-keystore.jks

  if [ -n "${KEY_STORE_PASSWORD:-}" ] && [ -n "${KEY_PASSWORD:-}" ] && [ -n "${KEY_ALIAS:-}" ]; then
    cat > android/key.properties <<PROPS
storePassword=$KEY_STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=release-keystore.jks
PROPS
    keystore_decoded=true
    echo "  Keystore decoded and key.properties written."
  else
    warn "KEY_STORE_PASSWORD / KEY_PASSWORD / KEY_ALIAS not set. Using debug signing."
  fi
else
  warn "KEYSTORE_BASE64 not set. Building with debug signing."
fi

# ---- Step 5: Analyze ----
step "Running Flutter analyze..."
flutter analyze --no-pub 2>/dev/null || flutter analyze

# ---- Step 6: Test ----
step "Running Flutter tests..."
flutter test --no-pub 2>/dev/null || flutter test

# ---- Step 7: Build APK ----
step "Building APK (release)..."
flutter build apk --release --no-pub 2>/dev/null || flutter build apk --release

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APP_DIR/$APK_PATH" ]; then
  APK_SIZE=$(du -h "$APP_DIR/$APK_PATH" | cut -f1)
  echo "  APK: $APK_PATH ($APK_SIZE)"
else
  fail "APK not found at $APK_PATH"
fi

# ---- Step 8: Build AAB ----
step "Building App Bundle (release)..."
flutter build appbundle --release --no-pub 2>/dev/null || flutter build appbundle --release

AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
if [ -f "$APP_DIR/$AAB_PATH" ]; then
  AAB_SIZE=$(du -h "$APP_DIR/$AAB_PATH" | cut -f1)
  echo "  AAB: $AAB_PATH ($AAB_SIZE)"
else
  warn "AAB not found at $AAB_PATH (may require Play Store signing)"
fi

# ---- Step 9: Get version ----
VERSION=$(grep 'version:' pubspec.yaml | head -1 | awk '{print $2}')

# ---- Step 10: Summary ----
echo ""
echo "============================================"
echo " Build Complete!"
echo "============================================"
echo " Tag:     $TAG"
echo " Version: $VERSION"
echo " APK:     $APP_DIR/$APK_PATH"
echo " AAB:     $APP_DIR/$AAB_PATH"
echo ""
if $keystore_decoded; then
  echo " Signing: RELEASE (production keystore)"
else
  echo " Signing: DEBUG (development only)"
fi
echo ""
echo " To publish: git tag $TAG && git push origin $TAG"
echo "============================================"
