#!/usr/bin/env bash
# =====================================
# config.sh - Centralized Configuration
# =====================================
# Source this file in all scripts to ensure consistent configuration
#
# Usage in scripts:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "${SCRIPT_DIR}/config.sh"

set -euo pipefail

# ========================================
# CORE PATHS
# ========================================
# Get absolute path to this script's directory (tools/xcframework-cli/)
TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Project root is 2 levels up from tools/xcframework-cli/
PROJECT_ROOT="$(cd "${TOOLS_DIR}/../.." && pwd)"

# Workspace root (contains multiple projects)
WORKSPACE_ROOT="$(cd "${PROJECT_ROOT}/.." && pwd)"

# ========================================
# SOURCE DIRECTORIES
# ========================================
# Main iOS project
IOS_PROJECT="${PROJECT_ROOT}"
IOS_PROJECT_FILE="${IOS_PROJECT}/luz_epost_ios.xcodeproj"

# SDK source directories
EPOSTSDK_SOURCE="${WORKSPACE_ROOT}/ePostSDK"

# ========================================
# BUILD OUTPUT PATHS
# ========================================
# Build artifacts directory
BUILD_DIR="${PROJECT_ROOT}/build"
DERIVED_DATA="${BUILD_DIR}/DerivedData"

# XCFramework output (in workspace, not project)
XCFRAMEWORK_OUTPUT_DIR="${EPOSTSDK_SOURCE}"

# Logs directory
LOG_DIR="${BUILD_DIR}/logs"

# ========================================
# SCRIPT PATHS
# ========================================
# Tools directory (where scripts live)
SCRIPTS_DIR="${TOOLS_DIR}"

# Template directory
TEMPLATES_DIR="${SCRIPTS_DIR}/templates"

# ========================================
# FRAMEWORK CONFIGURATIONS
# ========================================
# Framework names
EPOST_SDK_NAME="ePostSDK"
PUSH_NOTIFICATION_SDK_NAME="ePostPushNotificationSDK"

# ========================================
# HELPER FUNCTIONS
# ========================================
# Create required directories
ensure_directories() {
    mkdir -p "${BUILD_DIR}"
    mkdir -p "${DERIVED_DATA}"
    mkdir -p "${LOG_DIR}"
    mkdir -p "${XCFRAMEWORK_OUTPUT_DIR}/${EPOST_SDK_NAME}"
    mkdir -p "${XCFRAMEWORK_OUTPUT_DIR}/${PUSH_NOTIFICATION_SDK_NAME}"
}

# Print all configuration (for debugging)
print_config() {
    echo "========================================="
    echo "Build Configuration"
    echo "========================================="
    echo "TOOLS_DIR:               ${TOOLS_DIR}"
    echo "PROJECT_ROOT:            ${PROJECT_ROOT}"
    echo "WORKSPACE_ROOT:          ${WORKSPACE_ROOT}"
    echo ""
    echo "IOS_PROJECT:             ${IOS_PROJECT}"
    echo "IOS_PROJECT_FILE:        ${IOS_PROJECT_FILE}"
    echo "EPOSTSDK_SOURCE:         ${EPOSTSDK_SOURCE}"
    echo ""
    echo "BUILD_DIR:               ${BUILD_DIR}"
    echo "DERIVED_DATA:            ${DERIVED_DATA}"
    echo "XCFRAMEWORK_OUTPUT_DIR:  ${XCFRAMEWORK_OUTPUT_DIR}"
    echo "LOG_DIR:                 ${LOG_DIR}"
    echo ""
    echo "SCRIPTS_DIR:             ${SCRIPTS_DIR}"
    echo "TEMPLATES_DIR:           ${TEMPLATES_DIR}"
    echo ""
    echo "EPOST_SDK_NAME:          ${EPOST_SDK_NAME}"
    echo "PUSH_NOTIFICATION_SDK:   ${PUSH_NOTIFICATION_SDK_NAME}"
    echo "========================================="
}

# Validate configuration
validate_config() {
    local errors=0

    if [ ! -f "${IOS_PROJECT_FILE}" ]; then
        echo "❌ ERROR: Xcode project not found at ${IOS_PROJECT_FILE}"
        errors=$((errors + 1))
    fi

    if [ ! -d "${EPOSTSDK_SOURCE}" ]; then
        echo "⚠️  WARNING: ePostSDK directory not found at ${EPOSTSDK_SOURCE}"
        echo "   It will be created automatically"
    fi

    return $errors
}

# ========================================
# AUTO-INITIALIZATION
# ========================================
# Automatically create required directories when sourced
ensure_directories

# Optional: Enable debug mode
if [ "${DEBUG_CONFIG:-0}" = "1" ]; then
    print_config
fi

# Export all variables for use in child processes
export TOOLS_DIR PROJECT_ROOT WORKSPACE_ROOT
export IOS_PROJECT IOS_PROJECT_FILE EPOSTSDK_SOURCE
export BUILD_DIR DERIVED_DATA XCFRAMEWORK_OUTPUT_DIR LOG_DIR
export SCRIPTS_DIR TEMPLATES_DIR
export EPOST_SDK_NAME PUSH_NOTIFICATION_SDK_NAME
