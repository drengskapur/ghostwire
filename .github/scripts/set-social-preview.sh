#!/bin/bash
# Set GitHub repository social preview image using GitHub API
# This must be run AFTER pushing the brand assets to GitHub

set -e

REPO="drengskapur/ghostwire"
IMAGE_PATH="brand/hero/ghostwire-hero-1280x640.png"

echo "📸 Setting social preview image for ${REPO}..."
echo "Image: ${IMAGE_PATH}"
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found"
    echo "Install with: https://cli.github.com/"
    exit 1
fi

# Download the image from the repo
echo "📥 Downloading image from repository..."
curl -sL "https://raw.githubusercontent.com/${REPO}/main/${IMAGE_PATH}" -o /tmp/social-preview.png

# Upload as social preview using GitHub API
echo "📤 Uploading social preview image..."
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO}/social-preview" \
  --input /tmp/social-preview.png \
  2>&1 || {
    echo ""
    echo "⚠️  API upload failed - setting via web UI instead:"
    echo "  1. Go to https://github.com/${REPO}/settings"
    echo "  2. Scroll to 'Social preview'"
    echo "  3. Click 'Upload an image'"
    echo "  4. Select: ${IMAGE_PATH}"
    echo ""
    echo "Or use the image at:"
    echo "  https://raw.githubusercontent.com/${REPO}/main/${IMAGE_PATH}"
    exit 0
  }

# Clean up
rm -f /tmp/social-preview.png

echo ""
echo "✅ Social preview image set successfully!"
echo ""
echo "Preview at: https://github.com/${REPO}"
