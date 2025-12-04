#!/usr/bin/env bash

# =====================================
# Resource Bundle Accessor Injection Script
# =====================================
# This script injects a custom resource_bundle_accessor.swift template
# into build artifacts to support XCFramework distribution.
#
# Purpose:
#   - Finds SPM's auto-generated resource_bundle_accessor.swift
#   - Replaces it with custom template (extended search paths)
#   - Recompiles the .o file for the new accessor
#
# Usage:
#   source ./inject-resource-accessor.sh
#   inject_custom_resource_accessor "$OUTPUT_DIR" "$PLATFORM_NAME"
#
# Or call directly:
#   ./inject-resource-accessor.sh --output-dir <path> --platform <name>
#
# Arguments:
#   OUTPUT_DIR     - Build output directory containing artifacts
#   PLATFORM_NAME  - Platform name (e.g., "iOS Device", "iOS Simulator")
#
# Requirements:
#   - templates/resource_bundle_accessor.swift must exist
#   - xcodebuild artifacts must be present in OUTPUT_DIR
#   - swiftc must be available (via xcrun)
#
# Author: Phuong Doan Duy
# Copyright © 2025 AAVN. All rights reserved.

set -eo pipefail  # Exit on error, pipe failures

# === LOAD CONFIGURATION ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source config.sh if not already sourced
if [ -z "${TEMPLATES_DIR:-}" ]; then
    source "${SCRIPT_DIR}/config.sh"
fi

# === COLOR CODES ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# === PRINT FUNCTIONS ===

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# === INJECT CUSTOM RESOURCE BUNDLE ACCESSOR ===
# Inspired by xccache: https://github.com/trinhngocthuyen/xccache
# This function patches SPM's auto-generated resource_bundle_accessor.swift
# for ios_theme_ui dependencies embedded in XCFrameworks.
#
# Parameters:
#   $1 - OUTPUT_DIR: Build output directory
#   $2 - PLATFORM_NAME: Platform name (e.g., "iOS Device", "iOS Simulator")
#
# Returns:
#   0 - Success or no accessor found (normal)
#   1 - Error (template not found, compilation failed)

inject_custom_resource_accessor() {
    local output_dir="$1"
    local platform_name="$2"

    # Validate parameters
    if [ -z "$output_dir" ]; then
        print_error "OUTPUT_DIR parameter is required"
        return 1
    fi

    if [ -z "$platform_name" ]; then
        print_error "PLATFORM_NAME parameter is required"
        return 1
    fi

    # Try to find resource_bundle_accessor.swift ONLY in ios_theme_ui.build artifacts
    # This prevents accidentally modifying other dependencies (e.g., Kingfisher)
    local accessor_file=$(find "$output_dir" -path "*/ios_theme_ui.build/*/resource_bundle_accessor.swift" 2>/dev/null | head -1)

    print_info "Output directory: $output_dir"
    print_info "Accessor file: $accessor_file"

    if [ -z "$accessor_file" ]; then
        print_info "No resource accessor found for $platform_name (this is normal)"
        return 0
    fi

    print_info "Injecting custom resource accessor for $platform_name..."

    # Backup original SPM-generated file
    cp "$accessor_file" "${accessor_file}.original"

    # Get template path (from config.sh TEMPLATES_DIR)
    local template_path="${TEMPLATES_DIR}/resource_bundle_accessor.swift"

    # Verify template exists
    if [ ! -f "$template_path" ]; then
        print_error "Resource bundle accessor template not found at: $template_path"
        print_info "Expected location: epost-ios-theme-ui/scripts/templates/resource_bundle_accessor.swift"
        return 1
    fi

    # Replace SPM's generated file with custom template
    cp "$template_path" "$accessor_file"
    print_success "Template copied to: $(basename $(dirname $accessor_file))/$(basename $accessor_file)"

    # Find and recompile the .o file (only in ios_theme_ui.build)
    local object_file=$(find "$output_dir" -path "*/ios_theme_ui.build/*/resource_bundle_accessor*.o" 2>/dev/null | head -1)

    if [ -n "$object_file" ]; then
        # Determine SDK and target triple based on platform
        local sdk_path=""
        local target_triple=""

        if [[ "$platform_name" == *"Simulator"* ]]; then
            sdk_path=$(xcrun --sdk iphonesimulator --show-sdk-path)
            target_triple="arm64-apple-ios16.0-simulator"
        else
            sdk_path=$(xcrun --sdk iphoneos --show-sdk-path)
            target_triple="arm64-apple-ios16.0"
        fi

        # Remove old .o file
        rm -f "$object_file"

        # Recompile with swiftc
        if xcrun swiftc \
            -emit-library -emit-object \
            -module-name "ios_theme_ui" \
            -target "$target_triple" \
            -sdk "$sdk_path" \
            -o "$object_file" \
            "$accessor_file" 2>/dev/null; then
            print_success "Resource accessor compiled for $platform_name"
        else
            print_warning "Failed to recompile resource accessor for $platform_name"
            return 1
        fi
    else
        print_info "No .o file found to recompile (may not be required)"
    fi

    return 0
}

# === COMMAND LINE INTERFACE ===
# Allow script to be called directly (not just sourced)

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script is being executed directly, not sourced

    # Parse command line arguments
    OUTPUT_DIR=""
    PLATFORM_NAME=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --output-dir)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --platform)
                PLATFORM_NAME="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 --output-dir <path> --platform <name>"
                echo ""
                echo "Arguments:"
                echo "  --output-dir    Build output directory containing xcodebuild artifacts"
                echo "  --platform      Platform name (e.g., 'iOS Device', 'iOS Simulator')"
                echo ""
                echo "Example:"
                echo "  $0 --output-dir ./build --platform 'iOS Device'"
                exit 0
                ;;
            *)
                print_error "Unknown argument: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [ -z "$OUTPUT_DIR" ] || [ -z "$PLATFORM_NAME" ]; then
        print_error "Missing required arguments"
        echo "Use --help for usage information"
        exit 1
    fi

    # Call the function
    inject_custom_resource_accessor "$OUTPUT_DIR" "$PLATFORM_NAME"
    exit $?
fi

# If sourced, export the function
export -f inject_custom_resource_accessor 2>/dev/null || true
