#!/usr/bin/env bash
set -euo pipefail

# Generate CHANGELOG.md from git history using git-cliff
# Automatically installs git-cliff if not found

cd "$(dirname "$0")/.."

if ! command -v git-cliff &> /dev/null; then
  echo "⚠️  git-cliff not found. Installing..."

  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m)

  if [ "$ARCH" = "x86_64" ]; then
    ARCH="x86_64"
  elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    ARCH="aarch64"
  fi

  VERSION="2.10.1"
  URL="https://github.com/orhun/git-cliff/releases/download/v${VERSION}/git-cliff-${VERSION}-${ARCH}-unknown-${OS}-gnu.tar.gz"

  echo "📥 Downloading git-cliff ${VERSION}..."
  curl -sL "$URL" | sudo tar xz --strip-components=1 -C /usr/local/bin "git-cliff-${VERSION}/git-cliff"

  echo "✅ git-cliff installed to /usr/local/bin"
fi

echo "📝 Generating CHANGELOG.md..."
git-cliff --output CHANGELOG.md
echo "✅ CHANGELOG.md generated"
echo ""
echo "💡 Review: cat CHANGELOG.md"
