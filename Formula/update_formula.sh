#!/usr/bin/env bash
# update_formula.sh — update Formula/goplay2.rb for a new tag or commit hash.
#
# Usage:
#   ./Formula/update_formula.sh <tag-or-commit>
#
# Examples:
#   ./Formula/update_formula.sh v1.0.2
#   ./Formula/update_formula.sh abc1234
#
# The script will:
#   1. Download the GitHub archive tarball for the given ref.
#   2. Compute its SHA-256.
#   3. Patch the url and sha256 lines in Formula/goplay2.rb.
#   4. Optionally sync to the local Homebrew tap (librekeys/local).
#
# Requirements: curl, shasum (both ship with macOS).

set -euo pipefail

REPO="phoeagon/goplay2"
FORMULA_FILE="$(cd "$(dirname "$0")" && pwd)/goplay2.rb"
TAP_DIR="/opt/homebrew/Library/Taps/librekeys/homebrew-local/Formula"
TAP_FORMULA="$TAP_DIR/goplay2.rb"

# ── helpers ────────────────────────────────────────────────────────────────────
usage() {
  echo "Usage: $0 <tag-or-commit>"
  echo "  e.g. $0 v1.0.2   or   $0 abc1234"
  exit 1
}

# ── args ───────────────────────────────────────────────────────────────────────
REF="${1:-}"
[[ -z "$REF" ]] && usage

echo "==> Ref: $REF"

# Build archive URL (GitHub serves .tar.gz for both tags and commits)
TARBALL_URL="https://github.com/${REPO}/archive/${REF}.tar.gz"

echo "==> Downloading tarball to compute SHA-256..."
echo "    $TARBALL_URL"

SHA256=$(curl -fsSL "$TARBALL_URL" | shasum -a 256 | awk '{print $1}')

if [[ -z "$SHA256" ]]; then
  echo "ERROR: Could not compute SHA-256 (download may have failed)."
  exit 1
fi

echo "==> SHA-256: $SHA256"

# ── patch formula ──────────────────────────────────────────────────────────────
echo "==> Patching $FORMULA_FILE"

# url line
sed -i '' \
  "s|url \"https://github.com/${REPO}/archive/.*\"|url \"${TARBALL_URL}\"|" \
  "$FORMULA_FILE"

# sha256 line
sed -i '' \
  "s|sha256 \"[0-9a-f]*\"|sha256 \"${SHA256}\"|" \
  "$FORMULA_FILE"

echo "==> Done. New formula head:"
head -8 "$FORMULA_FILE"

# ── sync to local tap (optional) ───────────────────────────────────────────────
if [[ -d "$TAP_DIR" ]]; then
  echo "==> Syncing to local tap: $TAP_FORMULA"
  cp "$FORMULA_FILE" "$TAP_FORMULA"
  echo "==> Tap updated. Run:"
  echo "      brew reinstall librekeys/local/goplay2"
else
  echo "==> Local tap not found at $TAP_DIR — skipping sync."
  echo "    Copy manually: cp $FORMULA_FILE <tap>/Formula/goplay2.rb"
fi
