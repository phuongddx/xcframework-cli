#!/usr/bin/env bash

# =====================================
# Release Build Script
# =====================================
# Builds ePostSDK and ePostPushNotificationSDK for all platforms (device + simulator)
# and publishes them to Artifactory
#
# Usage:
#   ./release.sh

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Framework names
EPOST_SDK="ePostSDK"
PUSH_NOTIFICATION_SDK="ePostPushNotificationSDK"

# Scripts
BUILD_SCRIPT="${SCRIPT_DIR}/create-xcframework.sh"
PUBLISH_SCRIPT="${SCRIPT_DIR}/publish_to_artifactory.sh"

# Color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}ePostSDK Release Build${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Build ePostSDK
echo -e "${YELLOW}[1/2] Building ${EPOST_SDK} for all platforms...${NC}"
cd "${PROJECT_ROOT}"
"${BUILD_SCRIPT}" "${EPOST_SDK}" --all

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to build ${EPOST_SDK}${NC}"
    exit 1
fi
echo -e "${GREEN}✅ ${EPOST_SDK} built successfully${NC}"
echo ""

# Build ePostPushNotificationSDK
echo -e "${YELLOW}[2/2] Building ${PUSH_NOTIFICATION_SDK} for all platforms...${NC}"
cd "${PROJECT_ROOT}"
"${BUILD_SCRIPT}" "${PUSH_NOTIFICATION_SDK}" --all

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to build ${PUSH_NOTIFICATION_SDK}${NC}"
    exit 1
fi
echo -e "${GREEN}✅ ${PUSH_NOTIFICATION_SDK} built successfully${NC}"
echo ""

# Publish to Artifactory
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Publishing to Artifactory${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

if [ -f "${PUBLISH_SCRIPT}" ]; then
    cd "${PROJECT_ROOT}"
    "${PUBLISH_SCRIPT}"

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to publish to Artifactory${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Published to Artifactory successfully${NC}"
else
    echo -e "${RED}❌ Publish script not found: ${PUBLISH_SCRIPT}${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Release build completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
