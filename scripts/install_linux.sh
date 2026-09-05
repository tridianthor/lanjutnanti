#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/linux/x64/release/bundle"
INSTALL_DIR="$HOME/app/lanjutnanti"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter was not found on PATH." >&2
  exit 1
fi

cd "$PROJECT_ROOT"
echo "Building the Linux release..."
flutter build linux --release

if [[ ! -d "$BUILD_DIR" ]]; then
  echo "Linux build output was not found:" >&2
  echo "  $BUILD_DIR" >&2
  exit 1
fi

if [[ -e "$INSTALL_DIR" && ! -d "$INSTALL_DIR" ]]; then
  echo "The installation path exists but is not a directory:" >&2
  echo "  $INSTALL_DIR" >&2
  exit 1
fi

if [[ -d "$INSTALL_DIR" ]]; then
  echo "Replacing existing installation:"
  echo "  $INSTALL_DIR"
  rm -rf -- "$INSTALL_DIR"
else
  echo "Creating installation directory:"
  echo "  $INSTALL_DIR"
fi

mkdir -p -- "$INSTALL_DIR"
cp -a -- "$BUILD_DIR"/. "$INSTALL_DIR"/

echo "Linux installation completed:"
echo "  $INSTALL_DIR"
