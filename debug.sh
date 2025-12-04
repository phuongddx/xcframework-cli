#!/usr/bin/env bash

# =====================================
# Debug Build Script
# =====================================
# Builds ePostSDK and ePostPushNotificationSDK with platform options
#
# Usage:
#   ./debug.sh [OPTIONS]
#
# Options:
#   -all, --all           Build for device + simulator (default)
#   -device, --device     Build for device only
#   -simulator, --simulator Build for simulator only
#   -h, --help           Show this help message

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Framework names
EPOST_SDK="ePostSDK"
PUSH_NOTIFICATION_SDK="ePostPushNotificationSDK"

# Build script
BUILD_SCRIPT="${SCRIPT_DIR}/create-xcframework.sh"

# Default build option
BUILD_OPTION="--all"
BUILD_TYPE="all platforms"

# Color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -all, --all           Build for device + simulator (default)"
    echo "  -device, --device     Build for device only"
    echo "  -simulator, --simulator Build for simulator only"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build for all platforms"
    echo "  $0 --device           # Build for device only"
    echo "  $0 --simulator        # Build for simulator only"
    exit 0
}

# Parse arguments
for arg in "$@"; do
    case $arg in
        -all|--all)
            BUILD_OPTION="--all"
            BUILD_TYPE="all platforms (device + simulator)"
            ;;
        -device|--device)
            BUILD_OPTION="--device"
            BUILD_TYPE="device only"
            ;;
        -simulator|--simulator)
            BUILD_OPTION="--simulator"
            BUILD_TYPE="simulator only"
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $arg${NC}"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}ePostSDK Debug Build${NC}"
echo -e "${CYAN}Build type: ${BUILD_TYPE}${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Build ePostSDK
echo -e "${YELLOW}[1/2] Building ${EPOST_SDK} for ${BUILD_TYPE}...${NC}"
cd "${PROJECT_ROOT}"
"${BUILD_SCRIPT}" "${EPOST_SDK}" "${BUILD_OPTION}"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to build ${EPOST_SDK}${NC}"
    exit 1
fi
echo -e "${GREEN}✅ ${EPOST_SDK} built successfully${NC}"
echo ""

# Build ePostPushNotificationSDK
echo -e "${YELLOW}[2/2] Building ${PUSH_NOTIFICATION_SDK} for ${BUILD_TYPE}...${NC}"
cd "${PROJECT_ROOT}"
"${BUILD_SCRIPT}" "${PUSH_NOTIFICATION_SDK}" "${BUILD_OPTION}"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to build ${PUSH_NOTIFICATION_SDK}${NC}"
    exit 1
fi
echo -e "${GREEN}✅ ${PUSH_NOTIFICATION_SDK} built successfully${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Debug build completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
