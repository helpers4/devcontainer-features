#!/bin/bash

# Test script for local-mounts feature
# Copyright (c) 2025 helpers4
# Licensed under AGPL-3.0 - see LICENSE file for details

set -e

echo "Testing local-mounts feature..."

# Test 1: Check if GPG_TTY environment variable is set
if [ -n "$GPG_TTY" ]; then
    echo "✅ PASS: GPG_TTY environment variable is set: $GPG_TTY"
else
    echo "⚠️  WARN: GPG_TTY environment variable not set"
fi

# Test 2: Check if git is available
if command -v git >/dev/null 2>&1; then
    echo "✅ PASS: Git is available"
else
    echo "❌ FAIL: Git is not available"
    exit 1
fi

# Test 3: Check mount points exist (these may or may not have content depending on host)
TARGET_HOME="${HOME:-/home/node}"

echo "📁 Checking expected mount points at ${TARGET_HOME}..."

# Note: These tests check structure, not content (content depends on host configuration)
MOUNT_POINTS=(".gitconfig" ".ssh" ".gnupg" ".npmrc")
FOUND_COUNT=0

for mount in "${MOUNT_POINTS[@]}"; do
    if [ -e "${TARGET_HOME}/${mount}" ]; then
        echo "✅ PASS: ${mount} exists"
        FOUND_COUNT=$((FOUND_COUNT + 1))
    else
        echo "ℹ️  INFO: ${mount} not found (may not exist on host)"
    fi
done

echo ""
echo "🎉 local-mounts feature test complete!"
echo ""
echo "Test summary:"
echo "- Mount points found: ${FOUND_COUNT}/${#MOUNT_POINTS[@]}"
echo "- Note: Missing mount points may be normal if files don't exist on host"
