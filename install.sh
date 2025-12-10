#!/bin/bash
# Installation script for XCFramework CLI
# Usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/xcframework-cli/main/install.sh)"

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

REPO="phuongddx/xcframework-cli"
GEM_NAME="xcframework-cli"
COMMAND_NAME="xckit"
INSTALL_DIR="${HOME}/.xcframework-cli"
TEMP_DIR="/tmp/xcframework-cli-install"

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macOS";;
        Linux*)     echo "Linux";;
        CYGWIN*|MINGW*|MSYS*) echo "Windows";;
        *)          echo "Unknown";;
    esac
}

# Function to check if Ruby is installed
check_ruby() {
    if ! command -v ruby &> /dev/null; then
        print_error "Ruby is not installed. Please install Ruby first:"
        echo "  - macOS: brew install ruby"
        echo "  - Ubuntu: sudo apt-get install ruby-full"
        echo "  - Or visit: https://www.ruby-lang.org/en/downloads/"
        exit 1
    fi

    RUBY_VERSION=$(ruby -e 'puts RUBY_VERSION')
    print_info "Found Ruby version: $RUBY_VERSION"

    # Check minimum Ruby version (3.0)
    if ! ruby -e 'exit Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.0.0")' 2>/dev/null; then
        print_error "Ruby 3.0.0 or higher is required. Found version: $RUBY_VERSION"
        exit 1
    fi
}

# Function to check if gem command is available
check_gem() {
    if ! command -v gem &> /dev/null; then
        print_error "RubyGems is not available. Please ensure Ruby and RubyGems are properly installed."
        exit 1
    fi
}

# Function to get latest version from GitHub
get_latest_version() {
    local api_url="https://api.github.com/repos/$REPO/releases/latest"
    local version=$(curl -fsSL "$api_url" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -z "$version" ]; then
        print_warning "Could not fetch latest version, using master branch"
        echo "master"
    else
        echo "$version"
    fi
}

# Function to download and install the gem
install_gem() {
    local version="$1"
    local download_url

    print_info "Installing XCFramework CLI..."

    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"

    # Determine download URL
    if [ "$version" = "master" ]; then
        # Build from source
        print_info "Cloning repository..."
        git clone "https://github.com/$REPO.git" .

        print_info "Building gem..."
        if ! gem build "$GEM_NAME.gemspec"; then
            print_error "Failed to build gem"
            exit 1
        fi

        GEM_FILE=$(ls *.gem)
    else
        # Download pre-built gem
        download_url="https://github.com/$REPO/releases/download/$version/$GEM_NAME-${version#v}.gem"
        GEM_FILE="$GEM_NAME-${version#v}.gem"

        print_info "Downloading $GEM_FILE from GitHub..."
        if ! curl -fsSL -o "$GEM_FILE" "$download_url"; then
            print_error "Failed to download gem from: $download_url"
            exit 1
        fi
    fi

    # Install the gem
    print_info "Installing $GEM_FILE..."
    if ! gem install "$GEM_FILE" --install-dir "$INSTALL_DIR" --no-document; then
        print_error "Failed to install gem"
        exit 1
    fi

    print_info "Cleaning up..."
    rm -rf "$TEMP_DIR"
}

# Function to set up PATH
setup_path() {
    local shell_rc=""
    local gem_bin="$INSTALL_DIR/bin"
    local user_shell

    # Detect user's actual shell (not the script's shell)
    user_shell="${SHELL##*/}"
    
    # Determine RC file based on user's shell
    case "$user_shell" in
        zsh)
            shell_rc="$HOME/.zshrc"
            ;;
        bash)
            if [ "$(detect_os)" = "macOS" ]; then
                shell_rc="$HOME/.bash_profile"
            else
                shell_rc="$HOME/.bashrc"
            fi
            ;;
        fish)
            shell_rc="$HOME/.config/fish/config.fish"
            ;;
        *)
            shell_rc="$HOME/.profile"
            ;;
    esac

    # Check if already configured in RC file
    if [ -f "$shell_rc" ] && grep -q "XCFramework CLI" "$shell_rc" 2>/dev/null; then
        print_info "XCFramework CLI is already configured in $shell_rc"
        return
    fi

    # Add to PATH and GEM_PATH
    print_info "Adding gem binary directory to PATH in $shell_rc..."
    echo "" >> "$shell_rc"
    echo "# XCFramework CLI" >> "$shell_rc"
    echo "export GEM_HOME=\"$INSTALL_DIR\"" >> "$shell_rc"
    echo "export PATH=\"$gem_bin:\$PATH\"" >> "$shell_rc"

    print_warning "Please run 'source $shell_rc' or restart your terminal to use xckit command"
}

# Function to verify installation
verify_installation() {
    if [ -f "$INSTALL_DIR/bin/$COMMAND_NAME" ]; then
        print_success "Successfully installed XCFramework CLI!"
        echo ""
        echo "To get started:"
        echo "  $COMMAND_NAME --help"
        echo "  $COMMAND_NAME build --help"
        echo ""
        echo "For more information, visit: https://github.com/$REPO"
    else
        print_error "Installation verification failed"
        exit 1
    fi
}

# Main installation flow
main() {
    echo "XCFramework CLI Installer"
    echo "========================="
    echo ""

    # Check prerequisites
    check_ruby
    check_gem

    # Get version to install
    VERSION="${1:-$(get_latest_version)}"
    print_info "Installing version: $VERSION"

    # Install the gem
    install_gem "$VERSION"

    # Set up PATH if needed
    setup_path

    # Verify installation
    verify_installation
}

# Handle script arguments
if [ "$1" = "--version" ]; then
    get_latest_version
    exit 0
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "XCFramework CLI Installer"
    echo ""
    echo "Usage:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh)\""
    echo ""
    echo "Options:"
    echo "  --version    Show latest version number"
    echo "  --help       Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  GEM_INSTALL_DIR    Custom gem installation directory (default: \$HOME/.gem)"
    exit 0
fi

# Check for custom install directory
if [ -n "$GEM_INSTALL_DIR" ]; then
    INSTALL_DIR="$GEM_INSTALL_DIR"
fi

# Run main function
main "$1"