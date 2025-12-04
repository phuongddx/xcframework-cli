#!/usr/bin/env bash

# =====================================
# XCFramework Build Script Template (Sequential Builds)
# =====================================
# A simplified template for building XCFrameworks with sequential builds.
# Customize the CONFIGURATIONS section for your project.
#
# Usage:
#   chmod +x create-xcframework.sh
#   ./create-xcframework.sh <FRAMEWORK_NAME> [OPTIONS]
#
# Arguments:
#   FRAMEWORK_NAME  Name of the framework to build (required)
#
# Options:
#   --all           Build for both device and simulator (default)
#   --device        Build for device only
#   --simulator     Build for simulator only
#   --output-dir    Custom output directory for XCFramework
#   --no-clean      Skip cleaning build artifacts (faster rebuilds)
#   --verbose       Enable verbose xcodebuild output
#   --checksum      Generate SHA256 checksum for distribution
#   --help          Show help message

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# ========================================
# CONFIGURATIONS (CUSTOMIZE THIS SECTION)
# ========================================
PROJECT="luz_epost_ios.xcodeproj"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ========================================
# COMMAND LINE OPTIONS
# ========================================
SKIP_CLEAN=false
VERBOSE=false
GENERATE_CHECKSUM=false
BUILD_TARGET="all"  # Options: all, device, simulator
OUTPUT_CUSTOM_DIR=""  # Custom output directory (if specified)
FRAMEWORK_NAME=""

# Parse command line arguments
EXPECT_OUTPUT_DIR=false
for arg in "$@"; do
    case $arg in
        --all)
            BUILD_TARGET="all"
            ;;
        --device)
            BUILD_TARGET="device"
            ;;
        --simulator)
            BUILD_TARGET="simulator"
            ;;
        --output-dir=*)
            OUTPUT_CUSTOM_DIR="${arg#*=}"
            ;;
        --output-dir)
            # Next argument will be the directory path
            EXPECT_OUTPUT_DIR=true
            ;;
        --no-clean)
            SKIP_CLEAN=true
            ;;
        --verbose)
            VERBOSE=true
            ;;
        --checksum)
            GENERATE_CHECKSUM=true
            ;;
        --help)
            echo "Usage: $0 <FRAMEWORK_NAME> [OPTIONS]"
            echo ""
            echo "Arguments:"
            echo "  FRAMEWORK_NAME  Name of the framework to build (required)"
            echo ""
            echo "Options:"
            echo "  --all           Build for both device and simulator (default)"
            echo "  --device        Build for device only"
            echo "  --simulator     Build for simulator only"
            echo "  --output-dir    Custom output directory for XCFramework"
            echo "                  Default: ../../ePostSDK/\${FRAMEWORK_NAME}/"
            echo "  --no-clean      Skip cleaning build artifacts (faster rebuilds)"
            echo "  --verbose       Enable verbose xcodebuild output"
            echo "  --checksum      Generate SHA256 checksum for distribution"
            echo "  --help          Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 ePostSDK --device --checksum"
            echo "  $0 ePostSDK --output-dir=/custom/path"
            exit 0
            ;;
        -*)
            # Skip other options
            ;;
        *)
            # First non-option argument is the framework name
            if [ -z "$FRAMEWORK_NAME" ]; then
                FRAMEWORK_NAME="$arg"
            elif [ "$EXPECT_OUTPUT_DIR" = true ]; then
                OUTPUT_CUSTOM_DIR="$arg"
                EXPECT_OUTPUT_DIR=false
            fi
            ;;
    esac
done

# Validate framework name
if [ -z "$FRAMEWORK_NAME" ]; then
    echo "Error: FRAMEWORK_NAME is required"
    echo ""
    echo "Usage: $0 <FRAMEWORK_NAME> [OPTIONS]"
    echo ""
    echo "Example:"
    echo "  $0 ePostSDK --checksum"
    echo ""
    echo "Run '$0 --help' for more information"
    exit 1
fi

# Set scheme to match framework name
SCHEME="$FRAMEWORK_NAME"

# Set output paths based on framework name
OUTPUT_DIR="${PROJECT_ROOT}/build"
DERIVED_DATA_PATH="${OUTPUT_DIR}/DerivedData"

# Determine XCFramework output path
if [ -n "$OUTPUT_CUSTOM_DIR" ]; then
    # Custom output directory specified
    XCFRAMEWORK_PATH="${OUTPUT_CUSTOM_DIR}/${FRAMEWORK_NAME}.xcframework"
else
    # Default: Use convention-based path in ePostSDK directory
    # Resolve to absolute path for cleaner display
    mkdir -p "${PROJECT_ROOT}/../ePostSDK"
    EPOSTSDK_ROOT="$(cd "${PROJECT_ROOT}/../ePostSDK" && pwd)"
    XCFRAMEWORK_PATH="${EPOSTSDK_ROOT}/${FRAMEWORK_NAME}/${FRAMEWORK_NAME}.xcframework"
fi

# Create parent directory if it doesn't exist
XCFRAMEWORK_PARENT_DIR="$(dirname "$XCFRAMEWORK_PATH")"
mkdir -p "$XCFRAMEWORK_PARENT_DIR"

# ========================================
# SOURCE RESOURCE BUNDLE UTILITY
# ========================================
# Source the copy-resource-bundle.sh utility for resource bundle management
COPY_BUNDLE_SCRIPT="${SCRIPT_DIR}/copy-resource-bundle.sh"

if [ -f "$COPY_BUNDLE_SCRIPT" ]; then
    source "$COPY_BUNDLE_SCRIPT"
    echo "✨ Loaded resource bundle utility"
else
    echo "⚠️  Resource bundle utility not found at: $COPY_BUNDLE_SCRIPT"
    echo "   Resource bundle copying will be skipped"
fi

# ========================================
# SOURCE RESOURCE ACCESSOR INJECTION SCRIPT
# ========================================
# Source the inject-resource-accessor.sh script for resource accessor patching
INJECT_SCRIPT="${SCRIPT_DIR}/inject-resource-accessor.sh"

if [ -f "$INJECT_SCRIPT" ]; then
    source "$INJECT_SCRIPT"
    echo "✨ Loaded resource accessor injection script"
else
    echo "⚠️  Resource accessor injection script not found at: $INJECT_SCRIPT"
    echo "   Resource accessor injection will be skipped"
fi

# ========================================
# BUILD OUTPUT FORMATTER
# ========================================
XCODEBUILD_FORMATTER=""
if command -v xcbeautify >/dev/null 2>&1; then
    XCODEBUILD_FORMATTER="xcbeautify"
    echo "✨ xcbeautify detected - build output will be formatted"
elif command -v xcpretty >/dev/null 2>&1; then
    XCODEBUILD_FORMATTER="xcpretty"
    echo "✨ xcpretty detected - build output will be formatted"
else
    echo "ℹ️  No build output formatter detected; using raw xcodebuild output"
    echo "   Install xcbeautify for better output: brew install xcbeautify"
fi

# ========================================
# COLOR CODES FOR OUTPUT
# ========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ========================================
# PRINT FUNCTIONS
# ========================================

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_step() {
    echo -e "\n${CYAN}▶ [$1/$2] $3${NC}"
}

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

print_time() {
    local seconds=$1
    local minutes=$((seconds / 60))
    local remaining_seconds=$((seconds % 60))

    if [ $minutes -gt 0 ]; then
        echo "${minutes}m ${remaining_seconds}s"
    else
        echo "${seconds}s"
    fi
}

# ========================================
# ERROR HANDLING
# ========================================
cleanup_on_error() {
    print_error "Build failed! Cleaning up..."

    # Remove incomplete XCFramework
    if [ -d "$XCFRAMEWORK_PATH" ]; then
        rm -rf "$XCFRAMEWORK_PATH"
    fi

    exit 1
}

trap cleanup_on_error ERR

# ========================================
# XCODEBUILD WRAPPER
# ========================================
run_xcodebuild() {
    if [ "$VERBOSE" = true ]; then
        xcodebuild "$@"
    elif [ -n "$XCODEBUILD_FORMATTER" ]; then
        if ! (set -o pipefail; xcodebuild "$@" 2>&1 | "$XCODEBUILD_FORMATTER"); then
            print_warning "Formatter failed; rerunning xcodebuild without formatting..."
            xcodebuild "$@"
        fi
    else
        xcodebuild "$@"
    fi
}

# ========================================
# MAP PLATFORM NAME TO SDK IDENTIFIER
# ========================================
# Converts human-readable platform names to SDK identifiers
# used in UninstalledProducts paths
#
# Parameters:
#   $1 - platform_name: Human-readable name (e.g., "iOS Simulator")
#
# Returns:
#   SDK identifier (e.g., "iphonesimulator")
map_platform_to_sdk() {
    local platform_name="$1"

    if [[ "$platform_name" == *"Simulator"* ]]; then
        echo "iphonesimulator"
    else
        echo "iphoneos"
    fi
}

# ========================================
# BUILD FRAMEWORK FUNCTION
# ========================================

build_framework() {
    local archive_suffix="$1"     # "iOS" or "iOS-Simulator"
    local destination="$2"         # Platform destination
    local platform_name="$3"       # Human-readable name

    local archive_path="${OUTPUT_DIR}/${FRAMEWORK_NAME}-${archive_suffix}"
    local start_time=$(date +%s)

    print_header "Building for $platform_name"

    # Build archive with library evolution for ABI stability
    # - BUILD_LIBRARY_FOR_DISTRIBUTION: Enables module stability
    # - ARCHS="arm64": Build for ARM64 architecture (modern iOS devices and Apple Silicon simulators)
    # - EXCLUDED_ARCHS="x86_64": Exclude Intel architecture (legacy simulator architecture)
    # - OTHER_SWIFT_FLAGS: Skip module interface verification for faster builds
    run_xcodebuild archive \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$destination" \
        -archivePath "$archive_path" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        ARCHS="arm64" \
        ONLY_ACTIVE_ARCH=NO \
        EXCLUDED_ARCHS="x86_64" \
        OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    print_success "$platform_name build completed in $(print_time $duration)"

    # Clean private Swift interfaces (per Apple's recommendation)
    local swiftmodule_path="$archive_path.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule"
    if [ -d "$swiftmodule_path" ]; then
        find "$swiftmodule_path" -name "*.private.swiftinterface" -delete
        print_info "Removed private interfaces from $platform_name"
    fi

}

# ========================================
# COPY RESOURCE BUNDLES INTO FRAMEWORK
# ========================================
# SPM resource bundles need to be manually copied into the framework.
# This is critical for frameworks that depend on SPM packages with resources.
#
# When SPM packages have resources, they are built as separate bundles
# (e.g., "PackageName_PackageName.bundle") but aren't automatically copied
# into framework targets. This function handles that copying by delegating
# to the copy-resource-bundle.sh utility.
#
# Parameters:
#   $1 - archive_suffix: Archive suffix ("iOS" or "iOS-Simulator")
#   $2 - platform_name: Human-readable platform name
copy_resource_bundles() {
    local archive_suffix="$1"     # "iOS" or "iOS-Simulator"
    local platform_name="$2"       # Human-readable name

    # ========================================
    # CUSTOMIZE: List your resource bundle names here
    # ========================================
    # Example: If your SPM package is named "MyPackage" and has resources,
    # the bundle will typically be named "MyPackage_MyPackage.bundle"
    #
    # Uncomment and add your bundles:
    local resource_bundles=()
    resource_bundles+=("ios_theme_ui_ios_theme_ui.bundle")
    # resource_bundles+=("AnotherPackage_AnotherPackage.bundle")

    if [ ${#resource_bundles[@]} -eq 0 ]; then
        print_info "No resource bundles configured (skip if not needed)"
        return 0
    fi

    # Check if utility is available
    if ! command -v copy_resource_bundle_into_framework &> /dev/null; then
        print_warning "Resource bundle utility not available, skipping copy"
        return 0
    fi

    # Map platform name to SDK identifier
    local platform_sdk=$(map_platform_to_sdk "$platform_name")
    local archive_path="${OUTPUT_DIR}/${FRAMEWORK_NAME}-${archive_suffix}.xcarchive"

    print_header "Copying Resource Bundles for $platform_name"

    # Copy each resource bundle using the utility
    local success_count=0
    local total_count=${#resource_bundles[@]}

    for resource_bundle_name in "${resource_bundles[@]}"; do
        print_info "Processing: $resource_bundle_name"

        # Call the utility function with OUTPUT_DIR exported
        export OUTPUT_DIR  # Ensure utility can access OUTPUT_DIR

        if copy_resource_bundle_into_framework \
            "$archive_path" \
            "$platform_sdk" \
            "$FRAMEWORK_NAME" \
            "$resource_bundle_name"; then
            success_count=$((success_count + 1))
        else
            print_warning "Failed to copy $resource_bundle_name (non-fatal)"
        fi
    done

    # Summary
    if [ $success_count -eq $total_count ]; then
        print_success "All resource bundles copied ($success_count/$total_count)"
    elif [ $success_count -gt 0 ]; then
        print_warning "Some resource bundles copied ($success_count/$total_count)"
    else
        print_info "No resource bundles copied (may not be present)"
    fi

    return 0
}

# ========================================
# START BUILD
# ========================================
# Calculate total steps based on build target
if [ "$BUILD_TARGET" = "all" ]; then
    TOTAL_STEPS=6  # Both builds + all other steps
elif [ "$BUILD_TARGET" = "device" ] || [ "$BUILD_TARGET" = "simulator" ]; then
    TOTAL_STEPS=5  # One build + all other steps
fi

CURRENT_STEP=0
SCRIPT_START_TIME=$(date +%s)

print_header "Building ${FRAMEWORK_NAME} XCFramework"
echo "Configuration:"
echo "  • Build target: $BUILD_TARGET"
echo "  • Output path: $XCFRAMEWORK_PATH"
echo "  • Skip clean: $([ "$SKIP_CLEAN" = true ] && echo "yes" || echo "no")"
echo "  • Verbose: $([ "$VERBOSE" = true ] && echo "yes" || echo "no")"
echo "  • Generate checksum: $([ "$GENERATE_CHECKSUM" = true ] && echo "yes" || echo "no")"
echo ""

# ========================================
# STEP 1: CLEAN PREVIOUS BUILDS
# ========================================
CURRENT_STEP=$((CURRENT_STEP + 1))
print_step $CURRENT_STEP $TOTAL_STEPS "Cleaning Previous Builds"

if [ "$SKIP_CLEAN" = false ]; then
    if [ -d "$OUTPUT_DIR" ]; then
        rm -rf "$OUTPUT_DIR"
        print_info "Removed build directory"
    fi

    # Remove existing XCFramework
    if [ -d "$XCFRAMEWORK_PATH" ]; then
        rm -rf "$XCFRAMEWORK_PATH"
        print_info "Removed existing XCFramework"
    fi
else
    print_warning "Skipping clean (--no-clean enabled)"
fi

mkdir -p "$OUTPUT_DIR"

# Mark build directory as deletable by Xcode build system
xattr -w com.apple.xcode.CreatedByBuildSystem true "$OUTPUT_DIR" 2>/dev/null || true

print_success "Build environment ready"

# ========================================
# STEP 2: CLEAN BUILD STATE
# ========================================
CURRENT_STEP=$((CURRENT_STEP + 1))
print_step $CURRENT_STEP $TOTAL_STEPS "Cleaning Xcode Build State"

if [ "$SKIP_CLEAN" = false ]; then
    run_xcodebuild clean \
        -project "$PROJECT" \
        -scheme "$SCHEME"

    print_success "Build state cleaned"
else
    print_warning "Skipping Xcode clean"
fi

# ========================================
# STEP 3: BUILD iOS DEVICE (CONDITIONAL)
# ========================================
if [ "$BUILD_TARGET" = "all" ] || [ "$BUILD_TARGET" = "device" ]; then
    CURRENT_STEP=$((CURRENT_STEP + 1))
    print_step $CURRENT_STEP $TOTAL_STEPS "Building iOS Device"

    build_framework "iOS" "generic/platform=iOS" "iOS Device"
    copy_resource_bundles "iOS" "iOS Device"

    # Inject custom resource accessor for iOS Device
    if command -v inject_custom_resource_accessor &> /dev/null; then
        inject_custom_resource_accessor "$OUTPUT_DIR" "iOS Device"
    else
        print_info "Skipping resource accessor injection (function not available)"
    fi
fi

# ========================================
# STEP 4: BUILD iOS SIMULATOR (CONDITIONAL)
# ========================================
if [ "$BUILD_TARGET" = "all" ] || [ "$BUILD_TARGET" = "simulator" ]; then
    CURRENT_STEP=$((CURRENT_STEP + 1))
    print_step $CURRENT_STEP $TOTAL_STEPS "Building iOS Simulator"

    build_framework "iOS-Simulator" "generic/platform=iOS Simulator" "iOS Simulator"
    copy_resource_bundles "iOS-Simulator" "iOS Simulator"

    # Inject custom resource accessor for iOS Simulator
    if command -v inject_custom_resource_accessor &> /dev/null; then
        inject_custom_resource_accessor "$OUTPUT_DIR" "iOS Simulator"
    else
        print_info "Skipping resource accessor injection (function not available)"
    fi
fi

# ========================================
# STEP 5: CREATE XCFRAMEWORK
# ========================================
CURRENT_STEP=$((CURRENT_STEP + 1))
print_step $CURRENT_STEP $TOTAL_STEPS "Creating XCFramework"

# Verify archives exist based on build target
if [ "$BUILD_TARGET" = "all" ] || [ "$BUILD_TARGET" = "device" ]; then
    if [ ! -d "${OUTPUT_DIR}/${FRAMEWORK_NAME}-iOS.xcarchive" ]; then
        print_error "iOS archive not found. Build may have failed."
        exit 1
    fi
fi

if [ "$BUILD_TARGET" = "all" ] || [ "$BUILD_TARGET" = "simulator" ]; then
    if [ ! -d "${OUTPUT_DIR}/${FRAMEWORK_NAME}-iOS-Simulator.xcarchive" ]; then
        print_error "iOS Simulator archive not found. Build may have failed."
        exit 1
    fi
fi

# Build XCFramework creation command based on build target
XCFRAMEWORK_ARGS=()

if [ "$BUILD_TARGET" = "all" ] || [ "$BUILD_TARGET" = "device" ]; then
    XCFRAMEWORK_ARGS+=(-framework "${OUTPUT_DIR}/${FRAMEWORK_NAME}-iOS.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework")
    XCFRAMEWORK_ARGS+=(-debug-symbols "${OUTPUT_DIR}/${FRAMEWORK_NAME}-iOS.xcarchive/dSYMs/${FRAMEWORK_NAME}.framework.dSYM")
fi

if [ "$BUILD_TARGET" = "all" ] || [ "$BUILD_TARGET" = "simulator" ]; then
    XCFRAMEWORK_ARGS+=(-framework "${OUTPUT_DIR}/${FRAMEWORK_NAME}-iOS-Simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework")
    XCFRAMEWORK_ARGS+=(-debug-symbols "${OUTPUT_DIR}/${FRAMEWORK_NAME}-iOS-Simulator.xcarchive/dSYMs/${FRAMEWORK_NAME}.framework.dSYM")
fi

run_xcodebuild -create-xcframework "${XCFRAMEWORK_ARGS[@]}" -output "$XCFRAMEWORK_PATH"

print_success "XCFramework created"

# ========================================
# STEP 6: GENERATE CHECKSUM (OPTIONAL)
# ========================================
CURRENT_STEP=$((CURRENT_STEP + 1))
print_step $CURRENT_STEP $TOTAL_STEPS "Generating Checksum"

if [ "$GENERATE_CHECKSUM" = true ]; then
    if command -v shasum >/dev/null 2>&1; then
        CHECKSUM_FILE="${XCFRAMEWORK_PATH}.sha256"

        # Create tarball for checksumming (consistent across runs)
        tar -czf "${OUTPUT_DIR}/${FRAMEWORK_NAME}.tar.gz" -C "$(dirname "$XCFRAMEWORK_PATH")" "$(basename "$XCFRAMEWORK_PATH")"
        shasum -a 256 "${OUTPUT_DIR}/${FRAMEWORK_NAME}.tar.gz" | cut -d' ' -f1 > "$CHECKSUM_FILE"
        rm "${OUTPUT_DIR}/${FRAMEWORK_NAME}.tar.gz"

        CHECKSUM=$(cat "$CHECKSUM_FILE")
        print_success "SHA256: ${CHECKSUM:0:16}..."
    else
        print_warning "shasum not available, skipping checksum generation"
    fi
else
    print_info "Checksum generation skipped (use --checksum to enable)"
fi

# ========================================
# CLEANUP BUILD ARTIFACTS
# ========================================
print_info "Cleaning build artifacts..."
rm -rf "$OUTPUT_DIR"
print_success "Build artifacts cleaned"

# ========================================
# CALCULATE SIZE & DURATION
# ========================================
XCFRAMEWORK_SIZE=$(du -sh "$XCFRAMEWORK_PATH" | cut -f1)
SCRIPT_END_TIME=$(date +%s)
TOTAL_DURATION=$((SCRIPT_END_TIME - SCRIPT_START_TIME))

# ========================================
# BUILD SUMMARY
# ========================================
print_header "Build Summary"

echo "📦 Framework Details:"
echo "  • Name: ${FRAMEWORK_NAME}"
echo "  • Location: ${XCFRAMEWORK_PATH}"
echo "  • Size: ${XCFRAMEWORK_SIZE}"

if [ "$GENERATE_CHECKSUM" = true ] && [ -f "${XCFRAMEWORK_PATH}.sha256" ]; then
    echo "  • SHA256: $(cat "${XCFRAMEWORK_PATH}.sha256" | cut -c1-16)..."
fi

echo ""
echo "⏱️  Build Performance:"
echo "  • Total time: $(print_time $TOTAL_DURATION)"
echo "  • Build mode: Sequential"
echo ""

print_success "XCFramework build completed successfully!"
echo ""
echo "Next steps:"
echo "  • Verify architectures: lipo -info ${XCFRAMEWORK_PATH}/ios-arm64/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}"
echo "  • Test in your project or Swift Package"
echo ""
