#!/usr/bin/env bash

# Automatic File Headers DevContainer Feature
# Copyright (c) 2025 helpers4
# Licensed under AGPL-3.0 - see LICENSE file for details
#
# Configures VS Code automatic file headers with customizable templates

set -e

echo "🔧 Setting up auto-header devcontainer feature..."

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq is required but not found. Installing..."
    apt-get update >/dev/null
    apt-get install -y jq >/dev/null || {
        echo "❌ Failed to install jq"
        exit 1
    }
fi
HEADER_TYPE="${HEADERTYPE:-simple}"
PROJECT_NAME="${PROJECTNAME}"
LICENSE="${LICENSE:-MIT}"
COMPANY="${COMPANY}"
CONTRIBUTORS="${CONTRIBUTORS}"
SINCE_YEAR="${SINCEYEAR}"
CUSTOM_HEADER_LINES="${CUSTOMHEADERLINES}"

# If projectName not provided, use current directory name as fallback
if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME=$(basename "$PWD")
fi

# Set default since year if not provided
if [ -z "$SINCE_YEAR" ]; then
    SINCE_YEAR=$(date +%Y)
fi

# Validate header type
if [ "$HEADER_TYPE" != "simple" ] && [ "$HEADER_TYPE" != "custom" ]; then
    echo "❌ headerType must be 'simple' or 'custom'"
    exit 1
fi

# Validate custom header lines for custom type
if [ "$HEADER_TYPE" = "custom" ] && [ -z "$CUSTOM_HEADER_LINES" ]; then
    echo "❌ customHeaderLines is required when headerType is 'custom'"
    exit 1
fi

# Create configuration directory
CONFIG_DIR="/etc/h4-auto-header"
mkdir -p "$CONFIG_DIR"

# Store configuration as JSON using jq for proper formatting
jq -n \
  --arg headerType "$HEADER_TYPE" \
  --arg projectName "$PROJECT_NAME" \
  --arg license "$LICENSE" \
  --arg company "$COMPANY" \
  --arg contributors "$CONTRIBUTORS" \
  --arg sinceYear "$SINCE_YEAR" \
  --arg customHeaderLines "$CUSTOM_HEADER_LINES" \
  '{
    headerType: $headerType,
    projectName: $projectName,
    license: $license,
    company: $company,
    contributors: $contributors,
    sinceYear: $sinceYear,
    customHeaderLines: $customHeaderLines
  }' > "$CONFIG_DIR/config.json"

# Create helper script
cat > /usr/local/bin/h4-init-headers << 'SCRIPT_EOF'
#!/usr/bin/env bash

# Helper script to initialize file headers in VS Code

CONFIG_DIR=\"/etc/h4-auto-header\"
CONFIG_FILE=\"$CONFIG_DIR/config.json\"

if [ ! -f \"$CONFIG_FILE\" ]; then
    echo \"❌ Configuration file not found: $CONFIG_FILE\"
    echo \"   Please ensure auto-header feature is installed\"
    exit 1
fi

# Read configuration values (basic JSON parsing with grep/sed)
HEADER_TYPE=$(grep -o '"headerType": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
PROJECT_NAME=$(grep -o '"projectName": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
LICENSE=$(grep -o '"license": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
COMPANY=$(grep -o '"company": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
CONTRIBUTORS=$(grep -o '"contributors": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
SINCE_YEAR=$(grep -o '"sinceYear": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)
CUSTOM_HEADER_LINES=$(grep -o '"customHeaderLines": "[^"]*"' "$CONFIG_FILE" | cut -d'"' -f4)

# Format copyright year range
CURRENT_YEAR=$(date +%Y)
if [ "$SINCE_YEAR" = "$CURRENT_YEAR" ]; then
    COPYRIGHT_YEARS="$SINCE_YEAR"
else
    COPYRIGHT_YEARS="$SINCE_YEAR-$CURRENT_YEAR"
fi

# Prepare copyright line
if [ -n "$COMPANY" ]; then
    COPYRIGHT_ENTITY="$COMPANY"
else
    COPYRIGHT_ENTITY="$PROJECT_NAME"
fi

# Ensure VS Code settings directory exists
VSCODE_SETTINGS_DIR="${DEVCONTAINER_SETTINGS_DIR:-.vscode}"
mkdir -p "$VSCODE_SETTINGS_DIR"
SETTINGS_FILE="$VSCODE_SETTINGS_DIR/settings.json"

# Format copyright year range
CURRENT_YEAR=$(date +%Y)
if [ "$SINCE_YEAR" = "$CURRENT_YEAR" ]; then
    COPYRIGHT_YEARS="$SINCE_YEAR"
else
    COPYRIGHT_YEARS="$SINCE_YEAR-$CURRENT_YEAR"
fi

# Generate psi-header configuration
if [ "$HEADER_TYPE" = "simple" ]; then
    # Simple header format
    HEADER_LINES="[
      \"// This file is part of $PROJECT_NAME.\",
      \"// Copyright (C) $COPYRIGHT_YEARS $COPYRIGHT_ENTITY\",
      \"// SPDX-License-Identifier: $LICENSE\"
    ]"
    BEFORE="\"// This file is part of\""
else
    # Custom header format
    # Convert escaped newlines to actual array elements
    HEADER_LINES=$(echo "$CUSTOM_HEADER_LINES" | awk -F'\n' '{
        for (i=1; i<=NF; i++) {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
            if ($i != "") {
                gsub(/"/, "\\\"", $i)
                printf "      \"%s\"%s\n", $i, (i < NF ? "," : "")
            }
        }
    }')
    HEADER_LINES="[
$HEADER_LINES
    ]"
    BEFORE=$(echo "$CUSTOM_HEADER_LINES" | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    BEFORE="\"${BEFORE:0:30}\""
fi

# Create psi-header extension settings
PSI_HEADER_CONFIG="{
  \"psi-header.config\": {
    \"forceToTop\": true,
    \"fineGrainedMode\": false,
    \"initials\": [],
    \"authorName\": \"$COPYRIGHT_ENTITY\",
    \"authorEmail\": \"\",
    \"source\": \"defaultHeader\",
    \"sourceHeader\": [
      \"/*!\",
      \" * File: <<filename>>\",
      \" * Project: $PROJECT_NAME\",
      \" * License: $LICENSE\",
      \" */\"
    ],
    \"header\": $HEADER_LINES,
    \"mapLines\": {},
    \"changes\": [
      {
        \"regex\": \"@modified\",
        \"replaceWith\": \"@modified \$MOD\",
        \"yearOnly\": false,
        \"notMatch\": \"^minute\",
        \"isMultiline\": false
      }
    ],
    \"changeFrequency\": \"fileChange\",
    \"modAuthor\": \"Modified by $COPYRIGHT_ENTITY\",
    \"modDate\": true,
    \"modHour\": false,
    \"modMinute\": false,
    \"modYear\": true,
    \"exclude\": [
      \"node_modules\",
      \".git\",
      \"dist\",
      \"build\",
      \"coverage\"
    ],
    \"autoHeader\": \"autoSave\",
    \"update\": false,
    \"updateYear\": true
  }
}"

echo "📝 Generating psi-header configuration..."
echo "$PSI_HEADER_CONFIG" | python3 -m json.tool > /dev/null 2>&1 || {
    echo "⚠️  Warning: Configuration might have formatting issues"
}

# If settings.json exists, merge the configuration
if [ -f "$SETTINGS_FILE" ]; then
    echo "📦 Merging with existing VS Code settings..."
    # Create temporary file with merged settings
    python3 << PYTHON_MERGE
import json
import os

settings_file = "$SETTINGS_FILE"
psi_config = $PSI_HEADER_CONFIG

try:
    with open(settings_file, 'r') as f:
        settings = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    settings = {}

# Merge psi-header configuration
settings.update(psi_config)

# Write back with nice formatting
with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')

print("✅ Settings merged successfully")
PYTHON_MERGE
else
    echo "📝 Creating new VS Code settings file..."
    echo "$PSI_HEADER_CONFIG" | python3 -m json.tool > "$SETTINGS_FILE"
fi

echo "✅ PSI Header configuration initialized"
echo ""
echo "📋 Configuration applied:"
echo "   Header type: $HEADER_TYPE"
echo "   Project: $PROJECT_NAME"
echo "   License: $LICENSE"
if [ -n "$COMPANY" ]; then
    echo "   Company: $COMPANY"
fi
if [ -n "$CONTRIBUTORS" ]; then
    echo "   Contributors: $CONTRIBUTORS"
fi
echo "   Since year: $SINCE_YEAR"
echo ""
echo "💡 Tip: Run this script again in another project directory to apply to a different .vscode location"

SCRIPT_EOF

chmod +x /usr/local/bin/h4-init-headers

echo "✅ auto-header feature installed"
echo ""
echo "📋 Configuration:"
echo "   Header type: $HEADER_TYPE"
echo "   Project: $PROJECT_NAME"
echo "   License: $LICENSE"
if [ -n "$COMPANY" ]; then
    echo "   Company: $COMPANY"
fi
if [ -n "$CONTRIBUTORS" ]; then
    echo "   Contributors: $CONTRIBUTORS"
fi
echo "   Since year: $SINCE_YEAR"
echo ""
echo "💡 Next step: Run 'h4-init-headers' in your project to initialize file headers"
