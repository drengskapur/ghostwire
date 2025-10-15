#!/bin/bash
# Automated Cloudflare Tunnel Setup
# Creates tunnel via API, configures DNS, and sets up Kubernetes secret

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env.local"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Cloudflare Tunnel Automated Setup for Ghostwire Dev       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Load environment
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo -e "${RED}✗ Error: .env.local not found${NC}"
    exit 1
fi

# Configuration (from .env.local with defaults)
TUNNEL_NAME="${CF_TUNNEL_NAME:-ghostwire-dev}"
HOSTNAME="${CF_TUNNEL_HOSTNAME:-ghostwire-dev.adhoc-solutions.com}"
K8S_NAMESPACE="ghostwire"
K8S_SECRET_NAME="cloudflared-credentials"

# Verify required variables
if [ -z "$CF_API_TOKEN" ] || [ -z "$CF_ACCOUNT_ID" ] || [ -z "$CF_ZONE_ID" ]; then
    echo -e "${RED}✗ Error: Missing required environment variables${NC}"
    echo "Required: CF_API_TOKEN, CF_ACCOUNT_ID, CF_ZONE_ID"
    echo "Run: ./scripts/cf-env.sh first"
    exit 1
fi

echo -e "${GREEN}✓ Environment variables loaded${NC}"
echo -e "  Account ID: ${CF_ACCOUNT_ID}"
echo -e "  Zone ID: ${CF_ZONE_ID}"
echo -e "  Zone: ${CF_ZONE_NAME}"
echo ""

# Function to call Cloudflare API
cf_api() {
    local method="$1"
    local endpoint="$2"
    local data="$3"

    if [ -n "$data" ]; then
        curl -s -X "$method" "https://api.cloudflare.com/client/v4${endpoint}" \
            -H "Authorization: Bearer ${CF_API_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "https://api.cloudflare.com/client/v4${endpoint}" \
            -H "Authorization: Bearer ${CF_API_TOKEN}" \
            -H "Content-Type: application/json"
    fi
}

# Step 1: Check if tunnel already exists
echo -e "${YELLOW}[1/5] Checking for existing tunnel...${NC}"

TUNNEL_LIST=$(cf_api "GET" "/accounts/${CF_ACCOUNT_ID}/cfd_tunnel")
EXISTING_TUNNEL=$(echo "$TUNNEL_LIST" | jq -r ".result[] | select(.name == \"${TUNNEL_NAME}\") | .id")

if [ -n "$EXISTING_TUNNEL" ] && [ "$EXISTING_TUNNEL" != "null" ]; then
    echo -e "${YELLOW}⚠ Tunnel '${TUNNEL_NAME}' already exists (ID: ${EXISTING_TUNNEL})${NC}"
    TUNNEL_ID="$EXISTING_TUNNEL"

    # Get tunnel info
    TUNNEL_INFO=$(cf_api "GET" "/accounts/${CF_ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}")
    echo -e "${GREEN}✓ Using existing tunnel${NC}"
else
    # Step 2: Create new tunnel
    echo -e "${YELLOW}[2/5] Creating new tunnel: ${TUNNEL_NAME}...${NC}"

    # Generate tunnel secret (32 random bytes, base64 encoded)
    TUNNEL_SECRET=$(openssl rand -base64 32)

    CREATE_RESPONSE=$(cf_api "POST" "/accounts/${CF_ACCOUNT_ID}/cfd_tunnel" \
        "{\"name\": \"${TUNNEL_NAME}\", \"tunnel_secret\": \"${TUNNEL_SECRET}\"}")

    if echo "$CREATE_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
        TUNNEL_ID=$(echo "$CREATE_RESPONSE" | jq -r '.result.id')
        echo -e "${GREEN}✓ Tunnel created: ${TUNNEL_ID}${NC}"
    else
        echo -e "${RED}✗ Failed to create tunnel${NC}"
        echo "$CREATE_RESPONSE" | jq .
        exit 1
    fi
fi

# Step 3: Get tunnel token
echo -e "${YELLOW}[3/5] Retrieving tunnel token...${NC}"

TOKEN_RESPONSE=$(cf_api "GET" "/accounts/${CF_ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/token")

if echo "$TOKEN_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    TUNNEL_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.result')
    echo -e "${GREEN}✓ Tunnel token retrieved${NC}"
else
    echo -e "${RED}✗ Failed to get tunnel token${NC}"
    echo "$TOKEN_RESPONSE" | jq .
    exit 1
fi

# Step 4: Create or update DNS CNAME record
echo -e "${YELLOW}[4/5] Configuring DNS record for ${HOSTNAME}...${NC}"

# Check if DNS record exists
DNS_RECORDS=$(cf_api "GET" "/zones/${CF_ZONE_ID}/dns_records?type=CNAME&name=${HOSTNAME}")
EXISTING_DNS=$(echo "$DNS_RECORDS" | jq -r ".result[] | select(.name == \"${HOSTNAME}\") | .id")

TUNNEL_CNAME="${TUNNEL_ID}.cfargotunnel.com"

if [ -n "$EXISTING_DNS" ] && [ "$EXISTING_DNS" != "null" ]; then
    echo -e "${YELLOW}⚠ DNS record already exists, updating...${NC}"

    DNS_RESPONSE=$(cf_api "PUT" "/zones/${CF_ZONE_ID}/dns_records/${EXISTING_DNS}" \
        "{\"type\": \"CNAME\", \"name\": \"${HOSTNAME}\", \"content\": \"${TUNNEL_CNAME}\", \"ttl\": 1, \"proxied\": true}")
else
    DNS_RESPONSE=$(cf_api "POST" "/zones/${CF_ZONE_ID}/dns_records" \
        "{\"type\": \"CNAME\", \"name\": \"${HOSTNAME}\", \"content\": \"${TUNNEL_CNAME}\", \"ttl\": 1, \"proxied\": true}")
fi

if echo "$DNS_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ DNS record configured${NC}"
    echo -e "  ${HOSTNAME} → ${TUNNEL_CNAME}"
else
    echo -e "${RED}✗ Failed to create DNS record${NC}"
    echo "$DNS_RESPONSE" | jq .
    exit 1
fi

# Step 5: Create Kubernetes secret
echo -e "${YELLOW}[5/5] Creating Kubernetes secret...${NC}"

# Create namespace if it doesn't exist
kubectl create namespace "${K8S_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1

# Create secret with tunnel token
kubectl create secret generic "${K8S_SECRET_NAME}" \
    --namespace "${K8S_NAMESPACE}" \
    --from-literal=token="${TUNNEL_TOKEN}" \
    --dry-run=client -o yaml | kubectl apply -f - > /dev/null 2>&1

echo -e "${GREEN}✓ Kubernetes secret created: ${K8S_SECRET_NAME}${NC}"

# Step 6: Configure tunnel routes
echo -e "${YELLOW}[6/6] Configuring tunnel ingress routes...${NC}"

# Update tunnel configuration with ingress rules
# Route directly to HAProxy for VNC/WebSocket handling (no authentication)
CONFIG_RESPONSE=$(cf_api "PUT" "/accounts/${CF_ACCOUNT_ID}/cfd_tunnel/${TUNNEL_ID}/configurations" \
    "{
        \"config\": {
            \"ingress\": [
                {
                    \"hostname\": \"${HOSTNAME}\",
                    \"service\": \"http://ghostwire-haproxy.${K8S_NAMESPACE}.svc.cluster.local:6901\"
                },
                {
                    \"service\": \"http_status:404\"
                }
            ]
        }
    }")

if echo "$CONFIG_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Tunnel routes configured${NC}"
else
    echo -e "${YELLOW}⚠ Tunnel routes will be configured via Helm chart${NC}"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Setup Complete! ✓                                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Tunnel Details:${NC}"
echo -e "  Name:       ${TUNNEL_NAME}"
echo -e "  ID:         ${TUNNEL_ID}"
echo -e "  Hostname:   ${HOSTNAME}"
echo -e "  K8s Secret: ${K8S_SECRET_NAME} (namespace: ${K8S_NAMESPACE})"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Helm will automatically deploy cloudflared with these credentials"
echo -e "  2. Access your application at: ${GREEN}https://${HOSTNAME}${NC}"
echo ""
echo -e "${YELLOW}To verify the tunnel is running:${NC}"
echo -e "  kubectl get pods -n ${K8S_NAMESPACE} -l app.kubernetes.io/name=cloudflared"
echo ""
