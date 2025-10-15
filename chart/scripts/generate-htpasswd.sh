#!/usr/bin/env bash
set -euo pipefail

# Generate htpasswd entries for Signal chart authentication
#
# Usage:
#   ./generate-htpasswd.sh username password
#   ./generate-htpasswd.sh  # Interactive mode

if [ $# -eq 2 ]; then
    # Non-interactive mode
    USERNAME="$1"
    PASSWORD="$2"
else
    # Interactive mode
    echo "🔐 Generate htpasswd entry for Signal authentication"
    echo ""
    read -p "Username: " USERNAME
    read -sp "Password: " PASSWORD
    echo ""
fi

# Check if htpasswd is available
if ! command -v htpasswd &> /dev/null; then
    echo "Error: htpasswd not found. Install apache2-utils:"
    echo "  Ubuntu/Debian: sudo apt-get install apache2-utils"
    echo "  macOS: brew install httpd"
    echo "  RHEL/CentOS: sudo yum install httpd-tools"
    exit 1
fi

# Generate bcrypt hash
HASH=$(htpasswd -nbB "$USERNAME" "$PASSWORD" | cut -d: -f2)

# Output for values.yaml
echo ""
echo "✅ Generated htpasswd entry:"
echo ""
echo "auth:"
echo "  users:"
echo "    - \"$USERNAME:$HASH\""
echo ""
echo "📋 Add this to your values.yaml file or use --set:"
echo "  --set auth.users[0]=\"$USERNAME:$HASH\""
echo ""

# Generate cookie secret if openssl is available
if command -v openssl &> /dev/null; then
    COOKIE_SECRET=$(openssl rand -base64 32)
    echo "🍪 Generated cookie secret:"
    echo ""
    echo "auth:"
    echo "  cookieSecret: \"$COOKIE_SECRET\""
    echo ""
    echo "  --set auth.cookieSecret=\"$COOKIE_SECRET\""
    echo ""
fi

echo "💡 To add multiple users, generate entries separately and add them to values.yaml:"
echo ""
echo "auth:"
echo "  users:"
echo "    - \"user1:$HASH\""
echo "    - \"user2:\$(htpasswd -nbB user2 pass2 | cut -d: -f2)\""
