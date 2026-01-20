#!/usr/bin/env bash

# Local Mounts DevContainer Feature
# Copyright (c) 2025 helpers4
# Licensed under AGPL-3.0 - see LICENSE file for details
#
# Mounts local Git, SSH, GPG, and npm configuration files into the devcontainer

set -e

echo "🔧 Setting up local-mounts devcontainer feature..."

# Get the target username from options or default
TARGET_USER="${USERNAME:-node}"
TARGET_HOME="/home/${TARGET_USER}"

# Use root home if target user is root
if [ "$TARGET_USER" = "root" ]; then
    TARGET_HOME="/root"
fi

echo "📁 Target user: ${TARGET_USER}"
echo "📁 Target home: ${TARGET_HOME}"

# Configure Git if available
if [ -f "${TARGET_HOME}/.gitconfig" ]; then
    echo "✅ Git configuration found"
    if command -v git >/dev/null 2>&1; then
        git config --global --get user.name >/dev/null 2>&1 && echo "   - User: $(git config --global --get user.name)" || true
        git config --global --get user.email >/dev/null 2>&1 && echo "   - Email: $(git config --global --get user.email)" || true
    fi
else
    echo "⚠️  No Git configuration found at ${TARGET_HOME}/.gitconfig"
    echo "   You may need to set it up manually with:"
    echo "   git config --global user.name 'Your Name'"
    echo "   git config --global user.email 'your.email@example.com'"
fi

# Test SSH agent forwarding
if [ -n "$SSH_AUTH_SOCK" ] && [ -S "$SSH_AUTH_SOCK" ]; then
    echo "✅ SSH agent forwarding is working"
    if command -v ssh-add >/dev/null 2>&1; then
        if ssh-add -l >/dev/null 2>&1; then
            KEY_COUNT=$(ssh-add -l 2>/dev/null | wc -l)
            echo "   - ${KEY_COUNT} SSH key(s) loaded"
        else
            echo "   - No SSH keys loaded in agent"
        fi
    fi
elif [ -d "${TARGET_HOME}/.ssh" ]; then
    echo "✅ SSH directory mounted at ${TARGET_HOME}/.ssh"
    if [ -f "${TARGET_HOME}/.ssh/id_rsa" ] || [ -f "${TARGET_HOME}/.ssh/id_ed25519" ]; then
        echo "   - SSH keys found"
    fi
else
    echo "⚠️  SSH agent forwarding not detected and no .ssh directory found"
fi

# Test GPG setup
if command -v gpg >/dev/null 2>&1; then
    if [ -d "${TARGET_HOME}/.gnupg" ]; then
        if gpg --list-secret-keys >/dev/null 2>&1; then
            GPG_KEYS=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -c "^sec" || echo "0")
            echo "✅ GPG keys are available (${GPG_KEYS} secret key(s))"
        else
            echo "ℹ️  GPG directory mounted but no secret keys found"
        fi
    else
        echo "ℹ️  No GPG directory found (optional for commit signing)"
    fi
else
    echo "ℹ️  GPG not installed (optional for commit signing)"
fi

# Check npm authentication
if [ -f "${TARGET_HOME}/.npmrc" ]; then
    echo "✅ npm configuration file found at ${TARGET_HOME}/.npmrc"
    # Check if it contains authentication tokens (without revealing them)
    if grep -qE "(authToken|_auth|//.*:_)" "${TARGET_HOME}/.npmrc" 2>/dev/null; then
        echo "   - Authentication tokens detected"
    fi
else
    echo "ℹ️  No .npmrc found - private npm registries may require manual setup"
fi

echo ""
echo "🎉 Local development files mount verification complete!"
echo ""
echo "📋 Summary:"
echo "   This feature mounts your local configuration files into the container:"
echo "   - ~/.gitconfig → ${TARGET_HOME}/.gitconfig"
echo "   - ~/.ssh       → ${TARGET_HOME}/.ssh"
echo "   - ~/.gnupg     → ${TARGET_HOME}/.gnupg"
echo "   - ~/.npmrc     → ${TARGET_HOME}/.npmrc"
