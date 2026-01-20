#!/bin/bash

# Test script for shell-history-per-project feature
# Copyright (c) 2025 helpers4
# Licensed under AGPL-3.0 - see LICENSE file for details

set -e

echo "Testing shell-history-per-project feature..."

# Test 1: Check if history directory exists
HISTORY_DIR="/workspaces/.shell-history"
if [ ! -d "$HISTORY_DIR" ]; then
    echo "❌ FAIL: History directory $HISTORY_DIR does not exist"
    exit 1
fi
echo "✅ PASS: History directory exists"

# Detect which shells are available
HAS_ZSH=false
HAS_BASH=false
if command -v zsh >/dev/null 2>&1; then
    HAS_ZSH=true
fi
if command -v bash >/dev/null 2>&1; then
    HAS_BASH=true
fi

echo "ℹ️  Detected shells: zsh=$HAS_ZSH, bash=$HAS_BASH"

# Test for ZSH (only if zsh is installed)
if [ "$HAS_ZSH" = true ]; then
    ZSH_HISTORY="$HISTORY_DIR/.zsh_history"
    if [ ! -f "$ZSH_HISTORY" ]; then
        echo "❌ FAIL: ZSH history file $ZSH_HISTORY does not exist"
        exit 1
    fi
    echo "✅ PASS: ZSH history file exists"

    # Check if symbolic link is created
    HOME_ZSH_HISTORY="$HOME/.zsh_history"
    if [ -L "$HOME_ZSH_HISTORY" ]; then
        LINK_TARGET=$(readlink "$HOME_ZSH_HISTORY")
        if [ "$LINK_TARGET" = "$ZSH_HISTORY" ]; then
            echo "✅ PASS: ZSH symbolic link is correctly configured"
        else
            echo "⚠️  WARN: ZSH symbolic link points to $LINK_TARGET instead of $ZSH_HISTORY"
        fi
    fi

    # Check if .zshrc is updated with history configuration
    if [ -f "$HOME/.zshrc" ]; then
        if grep -q "HISTFILE=" "$HOME/.zshrc"; then
            echo "✅ PASS: .zshrc contains HISTFILE configuration"
        else
            echo "⚠️  WARN: .zshrc does not contain HISTFILE configuration"
        fi
    fi
fi

# Test for BASH (only if bash is installed)
if [ "$HAS_BASH" = true ]; then
    BASH_HISTORY="$HISTORY_DIR/.bash_history"
    if [ ! -f "$BASH_HISTORY" ]; then
        echo "❌ FAIL: BASH history file $BASH_HISTORY does not exist"
        exit 1
    fi
    echo "✅ PASS: BASH history file exists"

    # Check if symbolic link is created
    HOME_BASH_HISTORY="$HOME/.bash_history"
    if [ -L "$HOME_BASH_HISTORY" ]; then
        LINK_TARGET=$(readlink "$HOME_BASH_HISTORY")
        if [ "$LINK_TARGET" = "$BASH_HISTORY" ]; then
            echo "✅ PASS: BASH symbolic link is correctly configured"
        else
            echo "⚠️  WARN: BASH symbolic link points to $LINK_TARGET instead of $BASH_HISTORY"
        fi
    fi

    # Check if .bashrc is updated with history configuration
    if [ -f "$HOME/.bashrc" ]; then
        if grep -q "HISTFILE=" "$HOME/.bashrc"; then
            echo "✅ PASS: .bashrc contains HISTFILE configuration"
        else
            echo "⚠️  WARN: .bashrc does not contain HISTFILE configuration"
        fi
    fi
fi

# Test directory permissions
PERMISSIONS=$(stat -c "%a" "$HISTORY_DIR" 2>/dev/null || stat -f "%OLp" "$HISTORY_DIR" 2>/dev/null)
if [ "$PERMISSIONS" = "755" ]; then
    echo "✅ PASS: History directory has correct permissions (755)"
else
    echo "⚠️  WARN: History directory permissions are $PERMISSIONS instead of 755"
fi

echo ""
echo "🎉 All tests passed! shell-history-per-project feature is working correctly."
echo ""
echo "Test summary:"
echo "- History directory created: $HISTORY_DIR"
echo "- Shells configured: zsh=$HAS_ZSH, bash=$HAS_BASH"
