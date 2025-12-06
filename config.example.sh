#!/usr/bin/env bash

# =====================================
# Configuration Example
# =====================================
# Copy this file to a local configuration file and customize for your project
#
# Usage:
#   1. Copy this file: cp config.example.sh config.local.sh
#   2. Edit config.local.sh with your project-specific values
#   3. Source it before running scripts: source config.local.sh
#
# Or set these as environment variables in your shell profile

# ========================================
# PROJECT CONFIGURATION
# ========================================

# Xcode project name (without .xcodeproj extension)
# Example: "MyiOSApp"
export XCODE_PROJECT_NAME="MyProject"

# SDK output directory name (where XCFrameworks will be placed)
# This directory will be created in the workspace root
# Example: "MySDKs" or "Frameworks"
export SDK_OUTPUT_DIR_NAME="SDKOutput"

# ========================================
# FRAMEWORK CONFIGURATION
# ========================================

# Space-separated list of framework names to build
# These should match your Xcode scheme names
# Example: "MySDK MyUtilsSDK MyNetworkSDK"
export FRAMEWORK_NAMES="Framework1 Framework2"

# ========================================
# RESOURCE BUNDLE CONFIGURATION (Optional)
# ========================================

# Module name for resource bundle accessor (if using SPM resource bundles)
# Only needed if you have resource bundles that need custom accessor injection
# Example: "my_theme_ui" or "my_resources"
export RESOURCE_MODULE_NAME=""

# ========================================
# ARTIFACTORY CONFIGURATION (For Publishing)
# ========================================

# Version to publish (semantic versioning recommended)
# Example: "1.0.0", "2.1.3-beta"
export VERSION="1.0.0"

# Artifactory registry URL
# Example: "https://artifactory.example.com/artifactory/api/swift"
export ARTIFACTORY_URL="https://your-artifactory-url.com/artifactory/api/swift"

# Artifactory username
export ARTIFACTORY_USERNAME="your-username"

# JFrog access token (keep this secure!)
# Generate from: Artifactory > User Profile > Generate Token
export JFROG_ACCESS_TOKEN="your-access-token"

# Package scope (reverse domain notation)
# Example: "com.mycompany", "io.github.username"
export PACKAGE_SCOPE="com.example"

# ========================================
# GIT CONFIGURATION (Optional)
# ========================================

# Git branch to push releases to
# Default: "master"
export GIT_BRANCH="master"

# ========================================
# SLACK NOTIFICATION (Optional)
# ========================================

# Slack webhook URL for deployment notifications
# Leave empty to disable Slack notifications
# Example: "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
export SLACK_WEBHOOK_URL=""

# ========================================
# DEBUG MODE (Optional)
# ========================================

# Enable debug output for configuration
# Set to "1" to print configuration when sourcing config.sh
# Default: "0"
export DEBUG_CONFIG="0"

# ========================================
# EXAMPLE CONFIGURATIONS
# ========================================

# Example 1: Simple iOS SDK project
# export XCODE_PROJECT_NAME="MyiOSApp"
# export SDK_OUTPUT_DIR_NAME="SDKs"
# export FRAMEWORK_NAMES="MySDK"

# Example 2: Multiple frameworks
# export XCODE_PROJECT_NAME="CompanyApp"
# export SDK_OUTPUT_DIR_NAME="Frameworks"
# export FRAMEWORK_NAMES="CoreSDK NetworkSDK UISDK"
# export RESOURCE_MODULE_NAME="ui_resources"

# Example 3: With Artifactory publishing
# export XCODE_PROJECT_NAME="ProductApp"
# export FRAMEWORK_NAMES="ProductSDK"
# export VERSION="2.1.0"
# export ARTIFACTORY_URL="https://company.jfrog.io/artifactory/api/swift"
# export ARTIFACTORY_USERNAME="ci-user"
# export JFROG_ACCESS_TOKEN="your-secure-token"
# export PACKAGE_SCOPE="com.company.product"
# export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/XXX/YYY/ZZZ"

echo "✅ Configuration loaded from config.example.sh"
echo "   Customize these values for your project"

