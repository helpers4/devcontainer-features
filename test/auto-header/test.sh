#!/usr/bin/env bash

# Test script for auto-header feature

set -e

echo "🧪 Testing auto-header feature..."

# Test 1: Check if header configuration is available
echo ""
echo "Test 1: Checking if header configuration exists..."
if [ -d "/root/.vscode-server/extensions" ]; then
    if ls /root/.vscode-server/extensions | grep -q "psioniq.*psi-header"; then
        echo "✅ Header extension support found"
    else
        echo "⚠️  Header extension not yet installed (will install on VS Code first launch)"
    fi
fi

# Test 2: Check if h4-init-headers script exists and is executable
echo ""
echo "Test 2: Checking if helper script is installed..."
if [ -x /usr/local/bin/h4-init-headers ]; then
    echo "✅ h4-init-headers script found and executable"
else
    echo "❌ h4-init-headers script not found or not executable"
    exit 1
fi

# Test 3: Check configuration file
echo ""
echo "Test 3: Checking configuration file..."
CONFIG_FILE="/etc/h4-auto-header/config.json"
if [ -f "$CONFIG_FILE" ]; then
    echo "✅ Configuration file found: $CONFIG_FILE"
    echo "   Content:"
    cat "$CONFIG_FILE"
    
    # Verify it's valid JSON using jq
    if jq empty "$CONFIG_FILE" 2>/dev/null; then
        echo "✅ Configuration is valid JSON"
    else
        echo "❌ Configuration is not valid JSON"
        exit 1
    fi
else
    echo "❌ Configuration file not found"
    exit 1
fi

# Test 4: Verify configuration contains expected keys
echo ""
echo "Test 4: Verifying configuration contains required keys..."
for key in "headerType" "projectName" "license" "sinceYear"; do
    if grep -q "\"$key\"" "$CONFIG_FILE"; then
        echo "✅ Key '$key' found in configuration"
    else
        echo "❌ Key '$key' missing from configuration"
        exit 1
    fi
done

# Test 5: Check if script is readable and contains expected patterns
echo ""
echo "Test 5: Verifying helper script contains expected patterns..."
if grep -q "h4-auto-header" /usr/local/bin/h4-init-headers; then
    echo "✅ Helper script contains auto-header references"
else
    echo "❌ Helper script missing auto-header references"
    exit 1
fi

# Cleanup
cd /

echo ""
echo "✅ All tests passed!"
echo ""
echo "📋 Summary:"
echo "   - Header configuration feature installed successfully"
echo "   - h4-init-headers helper script is executable"
echo "   - Configuration file is valid and complete"
echo "   - Helper script is properly configured"
echo ""
echo "💡 Next: Users can run 'h4-init-headers' in their project to initialize headers"
