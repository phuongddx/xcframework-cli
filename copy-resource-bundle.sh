#!/usr/bin/env bash

# =====================================
# Resource Bundle Copy Script
# =====================================
# This script copies resource bundles into framework archives to support
# XCFramework distribution with embedded resources.
#
# Purpose:
#   - Finds resource bundles in build artifacts
#   - Copies them into the appropriate framework directory
#   - Supports configurable bundle names
#
# Usage:
#   source ./copy-resource-bundle.sh
#   copy_resource_bundle_into_framework "$ARCHIVE_PATH" "$PLATFORM_SDK" "$FRAMEWORK_NAME" ["$BUNDLE_NAME"]
#
# Or call directly:
#   ./copy-resource-bundle.sh --archive-path <path> --platform <sdk> --framework <name> [--bundle-name <name>]
#
# Arguments:
#   ARCHIVE_PATH   - Path to the .xcarchive file
#   PLATFORM_SDK   - Platform SDK name (e.g., "iphoneos", "iphonesimulator")
#   FRAMEWORK_NAME - Name of the framework
#   BUNDLE_NAME    - (Optional) Name of the resource bundle (default: ios_theme_ui_ios_theme_ui.bundle)
#
# Requirements:
#   - Build artifacts must be present in OUTPUT_DIR
#   - Framework must exist in archive path
#
# Author: Phuong Doan Duy
# Copyright © 2025 AAVN. All rights reserved.

set -eo pipefail  # Exit on error, pipe failures

# === SCRIPT DIRECTORY ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

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

# === COPY RESOURCE BUNDLE INTO FRAMEWORK ===
# This function finds and copies resource bundles from build artifacts
# into the framework directory within an archive.
#
# Parameters:
#   $1 - ARCHIVE_PATH: Path to the .xcarchive file
#   $2 - PLATFORM_SDK: Platform SDK name (e.g., "iphoneos", "iphonesimulator")
#   $3 - FRAMEWORK_NAME: Name of the framework
#   $4 - BUNDLE_NAME: (Optional) Name of the resource bundle
#
# Returns:
#   0 - Success or no bundle found (normal)
#   1 - Error (invalid parameters, framework not found)

copy_resource_bundle_into_framework() {
    local archive_path="$1"
    local platform_sdk="$2"
    local framework_name="$3"
    local bundle_name="${4:-ios_theme_ui_ios_theme_ui.bundle}"  # Default bundle name
    
    # Validate required parameters
    if [ -z "$archive_path" ]; then
        print_error "ARCHIVE_PATH parameter is required"
        return 1
    fi
    
    if [ -z "$platform_sdk" ]; then
        print_error "PLATFORM_SDK parameter is required"
        return 1
    fi
    
    if [ -z "$framework_name" ]; then
        print_error "FRAMEWORK_NAME parameter is required"
        return 1
    fi
    
    # Validate archive path exists
    if [ ! -d "$archive_path" ]; then
        print_error "Archive path does not exist: $archive_path"
        return 1
    fi
    
    echo "🔍 Searching for resource bundle for platform: $platform_sdk"
    
    # Search for the resource bundle in build artifacts
    # Use OUTPUT_DIR from parent script or default to PROJECT_DIR/build
    local output_dir="${OUTPUT_DIR:-${PROJECT_DIR}/build}"
    local bundle_source=$(find "$output_dir" -path "*/UninstalledProducts/${platform_sdk}/${bundle_name}" 2>/dev/null | head -1)
    
    if [ -n "$bundle_source" ] && [ -d "$bundle_source" ]; then
        local framework_path="${archive_path}/Products/Library/Frameworks/${framework_name}.framework"
        
        if [ -d "$framework_path" ]; then
            cp -R "$bundle_source" "$framework_path/"
            print_success "Copied resource bundle into framework ($platform_sdk)"
            print_info "Source: $(basename $bundle_source)"
            print_info "Destination: ${framework_name}.framework/"
        else
            print_error "Framework path not found: $framework_path"
            return 1
        fi
    else
        print_info "No resource bundle found for $platform_sdk (this is normal if not using ${bundle_name})"
    fi
    
    return 0
}

# === COMMAND LINE INTERFACE ===
# Allow script to be called directly (not just sourced)

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script is being executed directly, not sourced
    
    # Parse command line arguments
    ARCHIVE_PATH=""
    PLATFORM_SDK=""
    FRAMEWORK_NAME=""
    BUNDLE_NAME="ios_theme_ui_ios_theme_ui.bundle"
    VERBOSE=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --archive-path)
                ARCHIVE_PATH="$2"
                shift 2
                ;;
            --platform)
                PLATFORM_SDK="$2"
                shift 2
                ;;
            --framework)
                FRAMEWORK_NAME="$2"
                shift 2
                ;;
            --bundle-name)
                BUNDLE_NAME="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                echo "Usage: $0 --archive-path <path> --platform <sdk> --framework <name> [OPTIONS]"
                echo ""
                echo "Copy resource bundles into framework archives for XCFramework distribution."
                echo ""
                echo "Required Arguments:"
                echo "  --archive-path    Path to the .xcarchive file"
                echo "  --platform        Platform SDK name (e.g., 'iphoneos', 'iphonesimulator')"
                echo "  --framework       Name of the framework"
                echo ""
                echo "Optional Arguments:"
                echo "  --bundle-name     Name of the resource bundle (default: ios_theme_ui_ios_theme_ui.bundle)"
                echo "  --verbose         Show detailed output"
                echo "  --help            Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0 --archive-path ./build/ePostSDK-iOS.xcarchive --platform iphoneos --framework ePostSDK"
                echo "  $0 --archive-path ./build/ePostSDK-iOS-Simulator.xcarchive --platform iphonesimulator --framework ePostSDK --bundle-name custom.bundle"
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
    if [ -z "$ARCHIVE_PATH" ] || [ -z "$PLATFORM_SDK" ] || [ -z "$FRAMEWORK_NAME" ]; then
        print_error "Missing required arguments"
        echo "Use --help for usage information"
        exit 1
    fi

    # Enable verbose output if requested
    if [ "$VERBOSE" = true ]; then
        set -x
    fi

    # Call the function
    copy_resource_bundle_into_framework "$ARCHIVE_PATH" "$PLATFORM_SDK" "$FRAMEWORK_NAME" "$BUNDLE_NAME"
    exit $?
fi

# If sourced, export the function
export -f copy_resource_bundle_into_framework 2>/dev/null || true

