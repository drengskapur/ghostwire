#!/bin/bash
# Cloudflare Environment Setup
# Fetches account ID and zone ID for adhoc-solutions.com and updates .env.local

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env.local"
ZONE_NAME="adhoc-solutions.com"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Fetching Cloudflare account and zone information...${NC}"

# Source existing env file
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo -e "${RED}Error: .env.local not found${NC}"
    exit 1
fi

if [ -z "$CF_API_TOKEN" ]; then
    echo -e "${RED}Error: CF_API_TOKEN not set in .env.local${NC}"
    exit 1
fi

# Check if flarectl is installed
if ! command -v flarectl &> /dev/null; then
    echo -e "${YELLOW}flarectl not found. Installing...${NC}"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install cloudflare/cloudflare/flarectl
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        go install github.com/cloudflare/cloudflare-go/cmd/flarectl@latest
    else
        echo -e "${RED}Unsupported OS. Please install flarectl manually${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}Fetching zone information for ${ZONE_NAME}...${NC}"

# Use flarectl to get zone info
export CF_API_TOKEN
ZONE_INFO=$(flarectl zone info --zone="${ZONE_NAME}" 2>/dev/null || true)

if [ -z "$ZONE_INFO" ]; then
    echo -e "${RED}✗ Zone ${ZONE_NAME} not found or token invalid${NC}"
    echo -e "${YELLOW}Available zones:${NC}"
    flarectl zone list 2>&1 || echo "Failed to list zones"
    exit 1
fi

# Parse zone info from flarectl output
ZONE_ID=$(echo "$ZONE_INFO" | grep -oP '(?<=ID: )[a-z0-9]+' | head -1)
ACCOUNT_ID=$(flarectl zone list 2>/dev/null | grep "${ZONE_NAME}" | awk '{print $NF}' || echo "")

if [ -z "$ZONE_ID" ]; then
    echo -e "${RED}✗ Failed to get zone ID${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found zone: ${ZONE_NAME}${NC}"
echo -e "  Zone ID: ${ZONE_ID}"
[ -n "$ACCOUNT_ID" ] && echo -e "  Account ID: ${ACCOUNT_ID}"

# Update .env.local
echo -e "${YELLOW}Updating .env.local...${NC}"

# Remove old auto-populated values
sed -i.bak '/^# Auto-populated/,/^CF_ZONE_NAME=/d' "$ENV_FILE"

# Append new values
cat >> "$ENV_FILE" << EOF

# Auto-populated by cf-env.sh on $(date)
CF_ACCOUNT_ID=${ACCOUNT_ID}
CF_ZONE_ID=${ZONE_ID}
CF_ZONE_NAME=${ZONE_NAME}
EOF

echo -e "${GREEN}✓ Updated .env.local${NC}"
echo ""
echo -e "${GREEN}Environment variables set:${NC}"
echo -e "  CF_ACCOUNT_ID=${ACCOUNT_ID}"
echo -e "  CF_ZONE_ID=${ZONE_ID}"
echo -e "  CF_ZONE_NAME=${ZONE_NAME}"
echo ""
echo -e "${YELLOW}To use these variables, run:${NC}"
echo -e "  source .env.local"
