#!/usr/bin/env bash
set -euo pipefail

# =====================================
# Setup Script for Build Tools
# =====================================
# This script installs recommended build tools for the project.
#
# Usage:
#   ./scripts/setup.sh
#
# What it installs:
#   - Homebrew (if not already installed)
#   - xcbeautify (Xcode build output formatter)

# === COLOR CODES ===
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# === PRINT FUNCTIONS ===
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# === MAIN SETUP ===
print_header "Setup Build Tools for ePost iOS"

# === 1. CHECK/INSTALL HOMEBREW ===
echo "1️⃣  Checking Homebrew..."
if command -v brew >/dev/null 2>&1; then
    print_success "Homebrew already installed: $(brew --version | head -1)"
else
    print_info "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    print_success "Homebrew installed"
fi
echo ""

# === 2. CHECK/INSTALL XCBEAUTIFY ===
echo "2️⃣  Checking xcbeautify (build output formatter)..."
if command -v xcbeautify >/dev/null 2>&1; then
    print_success "xcbeautify already installed: $(xcbeautify --version)"
else
    print_info "Installing xcbeautify via Homebrew..."
    brew install xcbeautify
    print_success "xcbeautify installed"
fi
echo ""

# === SUMMARY ===
print_header "Setup Complete!"

echo "Installed tools:"
echo ""

if command -v brew >/dev/null 2>&1; then
    echo "  ✅ Homebrew: $(brew --version | head -1)"
fi

if command -v xcbeautify >/dev/null 2>&1; then
    echo "  ✅ xcbeautify: $(xcbeautify --version)"
fi

echo ""
print_success "You can now run: ./scripts/create-xcframework.sh ePostSDK"
echo ""
