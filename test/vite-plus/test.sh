#!/bin/bash

# Test script for vite-plus feature

set -e

# Source test framework
source dev-container-features-test-lib

# Feature-specific tests
check "node is available" command -v node

check "npm is available" command -v npm

check "vite CLI is available" command -v vite

check "vitest CLI is available" command -v vitest

# Check Oxc installation (optional)
if command -v oxc >/dev/null 2>&1; then
    check "oxc CLI is available" command -v oxc
    check "oxc version displays" oxc --version
else
    echo "⚠️  Oxc CLI not installed (installOxc=false or failed to install)"
fi

reportResults
