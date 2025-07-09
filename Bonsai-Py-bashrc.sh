#!/bin/bash

# PyBonsai Auto-Installer with Repository Download
# This script downloads PyBonsai and installs it to run on every terminal startup

set -e  # Exit on any error

# Configuration
REPO_URL="https://github.com/Ben-Edwards44/PyBonsai.git"
PYBONSAI_DIR="$HOME/.local/share/pybonsai"
STARTUP_SCRIPT="$PYBONSAI_DIR/startup.sh"
TEMP_DIR="/tmp/pybonsai_install"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check for git
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Installing git..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y git
        elif command -v yum &> /dev/null; then
            sudo yum install -y git
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y git
        else
            print_error "Could not install git automatically. Please install git manually:"
            echo "  Ubuntu/Debian: sudo apt install git"
            echo "  CentOS/RHEL: sudo yum install git"
            echo "  Fedora: sudo dnf install git"
            exit 1
        fi
    fi
    
    # Check for Python3
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 is not installed. Installing python3..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y python3
        elif command -v yum &> /dev/null; then
            sudo yum install -y python3
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y python3
        else
            print_error "Could not install python3 automatically. Please install python3 manually:"
            echo "  Ubuntu/Debian: sudo apt install python3"
            echo "  CentOS/RHEL: sudo yum install python3"
            echo "  Fedora: sudo dnf install python3"
            exit 1
        fi
    fi
    
    print_status "Dependencies satisfied:"
    print_info "  Git: $(git --version)"
    print_info "  Python3: $(python3 --version)"
}

# Clean up previous installation
cleanup_previous() {
    print_status "Cleaning up previous installation..."
    
    # Remove old installation directory
    if [ -d "$PYBONSAI_DIR" ]; then
        rm -rf "$PYBONSAI_DIR"
        print_status "Removed old installation"
    fi
    
    # Remove old entries from shell configs
    for config in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$config" ]; then
            sed -i '/# PyBonsai - ASCII tree generator/d' "$config" 2>/dev/null || true
            sed -i '/source.*pybonsai.*startup.sh/d' "$config" 2>/dev/null || true
            sed -i '/python3.*pybonsai.*main.py/d' "$config" 2>/dev/null || true
        fi
    done
    
    # Clean up temp directory
    rm -rf "$TEMP_DIR"
}

# Download PyBonsai repository
download_repo() {
    print_status "Downloading PyBonsai repository..."
    
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    
    # Clone repository
    git clone "$REPO_URL" "$TEMP_DIR" || {
        print_error "Failed to download repository"
        print_error "Please check your internet connection and try again"
        exit 1
    }
    
    print_status "Repository downloaded successfully"
}

# Install PyBonsai
install_pybonsai() {
    print_status "Installing PyBonsai..."
    
    # Create installation directory
    mkdir -p "$PYBONSAI_DIR"
    
    # Copy all Python files
    cp "$TEMP_DIR"/*.py "$PYBONSAI_DIR/" || {
        print_error "Failed to copy PyBonsai files"
        exit 1
    }
    
    # Make main script executable
    chmod +x "$PYBONSAI_DIR/main.py"
    
    # Copy README for reference
    if [ -f "$TEMP_DIR/README.md" ]; then
        cp "$TEMP_DIR/README.md" "$PYBONSAI_DIR/"
    fi
    
    print_status "PyBonsai installed to $PYBONSAI_DIR"
}

# Create startup script
create_startup_script() {
    print_status "Creating startup script..."
    
    cat > "$STARTUP_SCRIPT" << 'EOF'
#!/bin/bash

# PyBonsai startup script
PYBONSAI_DIR="$HOME/.local/share/pybonsai"

# Only run in interactive shells (not in scripts or non-interactive sessions)
if [[ $- == *i* ]]; then
    # Check if files exist and terminal is wide enough
    if [ -f "$PYBONSAI_DIR/main.py" ] && [ "${COLUMNS:-80}" -ge 40 ]; then
        # Run PyBonsai silently with error handling - 50% smaller tree
        (cd "$PYBONSAI_DIR" && python3 main.py --instant --wait 0 --width 40 --height 12 --layers 6 --start-len 8 2>/dev/null) || true
        echo ""  # Add newline for better formatting
    fi
fi
EOF
    
    chmod +x "$STARTUP_SCRIPT"
    print_status "Startup script created"
}

# Add to shell configuration
add_to_shell_config() {
    print_status "Adding to shell configuration..."
    
    # Detect shell and config file
    SHELL_CONFIG=""
    
    # Check what shell we're currently using
    if [[ "$SHELL" == *"bash"* ]] || [[ -n "$BASH_VERSION" ]]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [[ "$SHELL" == *"zsh"* ]] || [[ -n "$ZSH_VERSION" ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    else
        # Default to bashrc for most Linux distributions
        SHELL_CONFIG="$HOME/.bashrc"
        print_warning "Could not detect shell type, defaulting to .bashrc"
    fi
    
    # Create config file if it doesn't exist
    touch "$SHELL_CONFIG"
    
    # Add PyBonsai to shell config
    if ! grep -q "source $STARTUP_SCRIPT" "$SHELL_CONFIG" 2>/dev/null; then
        echo "" >> "$SHELL_CONFIG"
        echo "# PyBonsai - ASCII tree generator" >> "$SHELL_CONFIG"
        echo "source $STARTUP_SCRIPT" >> "$SHELL_CONFIG"
        print_status "Added to $SHELL_CONFIG"
    else
        print_warning "Already added to $SHELL_CONFIG"
    fi
}

# Create management scripts
create_management_scripts() {
    print_status "Creating management scripts..."
    
    # Create update script
    cat > "$PYBONSAI_DIR/update.sh" << EOF
#!/bin/bash
echo "Updating PyBonsai..."
TEMP_DIR="/tmp/pybonsai_update"
rm -rf "\$TEMP_DIR"
git clone "$REPO_URL" "\$TEMP_DIR"
cp "\$TEMP_DIR"/*.py "$PYBONSAI_DIR/"
chmod +x "$PYBONSAI_DIR/main.py"
rm -rf "\$TEMP_DIR"
echo "PyBonsai updated successfully!"
EOF
    
    # Create uninstaller
    cat > "$PYBONSAI_DIR/uninstall.sh" << EOF
#!/bin/bash
echo "Uninstalling PyBonsai..."

# Remove from shell configs
for config in "\$HOME/.bashrc" "\$HOME/.zshrc"; do
    if [ -f "\$config" ]; then
        sed -i '/# PyBonsai - ASCII tree generator/d' "\$config" 2>/dev/null || true
        sed -i '/source.*pybonsai.*startup.sh/d' "\$config" 2>/dev/null || true
    fi
done

# Remove directory
rm -rf "$PYBONSAI_DIR"

echo "PyBonsai uninstalled successfully!"
echo "Please restart your terminal or run: source ~/.bashrc"
EOF
    
    # Create manual run script
    cat > "$PYBONSAI_DIR/run.sh" << EOF
#!/bin/bash
cd "$PYBONSAI_DIR"
python3 main.py "\$@"
EOF
    
    # Make scripts executable
    chmod +x "$PYBONSAI_DIR/update.sh"
    chmod +x "$PYBONSAI_DIR/uninstall.sh"
    chmod +x "$PYBONSAI_DIR/run.sh"
    
    print_status "Management scripts created"
}

# Test installation
test_installation() {
    print_status "Testing PyBonsai installation..."
    
    if (cd "$PYBONSAI_DIR" && python3 main.py --instant --help) &>/dev/null; then
        print_status "PyBonsai is working correctly!"
    else
        print_error "PyBonsai test failed. Please check the installation."
        exit 1
    fi
}

# Display success message
show_success() {
    echo ""
    echo "========================================="
    echo -e "${GREEN}PyBonsai Installation Complete!${NC}"
    echo "========================================="
    echo ""
    echo "PyBonsai will now display a tree every time you open a terminal."
    echo ""
    echo "Available commands:"
    echo "  • Test now: $PYBONSAI_DIR/run.sh"
    echo "  • Update: $PYBONSAI_DIR/update.sh"
    echo "  • Uninstall: $PYBONSAI_DIR/uninstall.sh"
    echo ""
    echo "To test the installation:"
    echo "  1. Open a new terminal window"
    echo "  2. Or run: source ~/.bashrc"
    echo ""
    echo "To customize PyBonsai options, edit: $STARTUP_SCRIPT"
    echo ""
    echo "Repository: $REPO_URL"
    echo "Installation directory: $PYBONSAI_DIR"
    echo ""
}

# Main installation function
main() {
    echo "=============================================="
    echo "PyBonsai Auto-Installer"
    echo "=============================================="
    echo ""
    echo "This script will:"
    echo "• Download PyBonsai from GitHub"
    echo "• Install it to ~/.local/share/pybonsai"
    echo "• Configure it to run on terminal startup"
    echo ""
    
    # Ask for confirmation
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    echo ""
    
    # Run installation steps
    check_dependencies
    cleanup_previous
    download_repo
    install_pybonsai
    create_startup_script
    add_to_shell_config
    create_management_scripts
    test_installation
    
    # Clean up temp directory
    rm -rf "$TEMP_DIR"
    
    show_success
}

# Handle script interruption
trap 'echo ""; print_error "Installation interrupted"; rm -rf "$TEMP_DIR"; exit 1' INT TERM

# Run main function
main "$@"
