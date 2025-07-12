#!/bin/bash

# Master JWM Wallpaper Slideshow Installer
# For Sparky Linux Bonsai DebianDog
# Author: Custom installer for bonsai remaster

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WALLPAPER_DIR="/home/x/Wallpapers/BONSAI-WALLPAPERS"
SCRIPT_PATH="/usr/local/bin/wallpaper-slideshow"
GITHUB_BASE_URL="https://raw.githubusercontent.com/GlitchLinux/Sparky-Bonsai-ASCII/main/BONSAI-WALLPAPERS"

# Wallpaper files to download
WALLPAPERS=(
    "bonsai1-FUZZ.png"
    "bonsai2-FUZZ.png"
    "bonsai3-FUZZ.png"
    "bonsai4-FUZZ.png"
    "bonsai5-FUZZ.png"
)

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}  JWM Wallpaper Slideshow Installer  ${NC}"
    echo -e "${BLUE}  Sparky Linux Bonsai DebianDog      ${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo
}

# Function to check if running as root when needed
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Do not run this script as root!"
        print_status "Run as normal user. Script will prompt for sudo when needed."
        exit 1
    fi
}

# Function to check dependencies
check_dependencies() {
    print_status "Checking system dependencies..."
    
    # Check if wget or curl is available
    if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
        print_error "Neither wget nor curl found. Installing wget..."
        sudo apt update && sudo apt install -y wget
    fi
    
    # Install required packages
    print_status "Installing required packages..."
    sudo apt update
    sudo apt install -y feh wget
    
    print_success "Dependencies installed successfully"
}

# Function to create wallpaper directory
create_wallpaper_directory() {
    print_status "Creating wallpaper directory..."
    
    # Create directory structure
    mkdir -p "$WALLPAPER_DIR"
    
    # Set proper permissions
    chmod 755 "$WALLPAPER_DIR"
    
    print_success "Wallpaper directory created: $WALLPAPER_DIR"
}

# Function to download wallpapers
download_wallpapers() {
    print_status "Downloading bonsai wallpapers from GitHub..."
    
    cd "$WALLPAPER_DIR"
    
    for wallpaper in "${WALLPAPERS[@]}"; do
        local url="${GITHUB_BASE_URL}/${wallpaper}"
        print_status "Downloading $wallpaper..."
        
        if command -v wget >/dev/null 2>&1; then
            wget -q --show-progress "$url" -O "$wallpaper"
        elif command -v curl >/dev/null 2>&1; then
            curl -L -o "$wallpaper" "$url"
        fi
        
        if [[ -f "$wallpaper" ]]; then
            print_success "Downloaded: $wallpaper"
        else
            print_error "Failed to download: $wallpaper"
            exit 1
        fi
    done
    
    # Set proper permissions
    chmod 644 *.png
    
    print_success "All wallpapers downloaded successfully"
    echo
    print_status "Wallpapers location: $WALLPAPER_DIR"
    ls -la "$WALLPAPER_DIR"
}

# Function to install wallpaper slideshow script
install_slideshow_script() {
    print_status "Installing wallpaper slideshow script..."
    
    # Create the main wallpaper slideshow script
    sudo tee "$SCRIPT_PATH" > /dev/null << 'SCRIPT_EOF'
#!/bin/bash

# JWM Wallpaper Slideshow Script for Sparky Linux Bonsai DebianDog
# Author: Custom script for bonsai remaster  
# Description: Cycles through wallpapers every 10 minutes
# Note: Stops PCManFM desktop mode and uses feh for wallpaper management

# Configuration
WALLPAPER_DIR="/home/x/Wallpapers/BONSAI-WALLPAPERS"
INTERVAL=600  # 10 minutes in seconds
LOCK_FILE="/tmp/wallpaper_slideshow.lock"
LOG_FILE="/tmp/wallpaper_slideshow.log"
STATE_FILE="/tmp/wallpaper_current_index"
PCMANFM_DISABLED_FLAG="/tmp/pcmanfm_disabled_by_wallpaper"

# Wallpaper files array
WALLPAPERS=(
    "bonsai1-FUZZ.png"
    "bonsai2-FUZZ.png"
    "bonsai3-FUZZ.png"
    "bonsai4-FUZZ.png"
    "bonsai5-FUZZ.png"
)

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to check if feh is available
check_feh() {
    if ! command -v feh >/dev/null 2>&1; then
        echo "ERROR: feh is not installed. Please install it:"
        echo "  sudo apt update && sudo apt install feh"
        log_message "ERROR: feh not found"
        exit 1
    fi
}

# Function to disable PCManFM desktop mode
disable_pcmanfm_desktop() {
    # Check if PCManFM is running in desktop mode
    if pgrep -f "pcmanfm.*--desktop" >/dev/null; then
        log_message "INFO: Stopping PCManFM desktop mode"
        killall pcmanfm 2>/dev/null
        # Wait a moment for process to terminate
        sleep 1
        # Mark that we disabled it
        touch "$PCMANFM_DISABLED_FLAG"
        echo "Stopped PCManFM desktop mode to enable wallpaper slideshow"
    fi
}

# Function to re-enable PCManFM desktop mode
enable_pcmanfm_desktop() {
    if [[ -f "$PCMANFM_DISABLED_FLAG" ]]; then
        log_message "INFO: Restarting PCManFM desktop mode"
        pcmanfm --desktop &
        rm -f "$PCMANFM_DISABLED_FLAG"
        echo "Restored PCManFM desktop mode"
    fi
}

# Function to set wallpaper using feh
set_wallpaper() {
    local wallpaper_path="$1"
    
    # Set wallpaper with feh
    if feh --bg-fill "$wallpaper_path" 2>/dev/null; then
        # Also create .fehbg script for restoration
        echo "#!/bin/sh" > ~/.fehbg
        echo "feh --bg-fill '$wallpaper_path'" >> ~/.fehbg
        chmod +x ~/.fehbg
        
        # Force refresh the desktop
        xrefresh 2>/dev/null || true
        
        return 0
    else
        return 1
    fi
}

# Function to restore wallpaper (useful after JWM restart)
restore_wallpaper() {
    if [[ -f ~/.fehbg ]]; then
        log_message "INFO: Restoring wallpaper from .fehbg"
        ~/.fehbg 2>/dev/null
    fi
}

# Function to get current wallpaper index
get_current_index() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "0"
    fi
}

# Function to save current wallpaper index
save_current_index() {
    echo "$1" > "$STATE_FILE"
}

# Function to get next wallpaper index
get_next_index() {
    local current_index=$(get_current_index)
    local next_index=$(( (current_index + 1) % ${#WALLPAPERS[@]} ))
    echo "$next_index"
}

# Function to change wallpaper
change_wallpaper() {
    check_feh
    
    local index=$(get_next_index)
    local wallpaper_file="${WALLPAPERS[$index]}"
    local wallpaper_path="$WALLPAPER_DIR/$wallpaper_file"
    
    if [[ ! -f "$wallpaper_path" ]]; then
        log_message "ERROR: Wallpaper file not found: $wallpaper_path"
        echo "ERROR: Wallpaper file not found: $wallpaper_path"
        return 1
    fi
    
    if set_wallpaper "$wallpaper_path"; then
        save_current_index "$index"
        log_message "SUCCESS: Changed wallpaper to $wallpaper_file (index: $index)"
        echo "Changed wallpaper to: $wallpaper_file"
        return 0
    else
        log_message "ERROR: Failed to set wallpaper: $wallpaper_path"
        echo "ERROR: Failed to set wallpaper: $wallpaper_path"
        return 1
    fi
}

# Function to start slideshow daemon
start_slideshow() {
    # Check if already running
    if [[ -f "$LOCK_FILE" ]]; then
        local pid=$(cat "$LOCK_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Slideshow already running with PID $pid"
            log_message "INFO: Slideshow already running with PID $pid"
            exit 0
        else
            log_message "INFO: Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi
    
    check_feh
    
    # Disable PCManFM desktop mode
    disable_pcmanfm_desktop
    
    # Create lock file
    echo $$ > "$LOCK_FILE"
    
    # Set initial wallpaper
    change_wallpaper
    
    log_message "INFO: Starting wallpaper slideshow daemon (PID: $$)"
    echo "Started wallpaper slideshow daemon"
    
    # Trap to cleanup on exit
    trap 'cleanup_and_exit' EXIT INT TERM
    
    # Main slideshow loop
    while true; do
        sleep "$INTERVAL"
        change_wallpaper
    done
}

# Function to cleanup and exit
cleanup_and_exit() {
    log_message "INFO: Slideshow daemon stopping"
    rm -f "$LOCK_FILE"
    exit 0
}

# Function to stop slideshow daemon
stop_slideshow() {
    if [[ -f "$LOCK_FILE" ]]; then
        local pid=$(cat "$LOCK_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            # Wait for process to terminate
            sleep 2
            rm -f "$LOCK_FILE"
            
            # Re-enable PCManFM if we disabled it
            enable_pcmanfm_desktop
            
            log_message "INFO: Stopped wallpaper slideshow daemon (PID: $pid)"
            echo "Stopped wallpaper slideshow daemon"
        else
            log_message "INFO: No running slideshow daemon found"
            echo "No running slideshow daemon found"
            rm -f "$LOCK_FILE"
        fi
    else
        echo "Slideshow not running"
    fi
}

# Function to check slideshow status
status_slideshow() {
    if [[ -f "$LOCK_FILE" ]]; then
        local pid=$(cat "$LOCK_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Wallpaper slideshow is running (PID: $pid)"
            local current_index=$(get_current_index)
            echo "Current wallpaper: ${WALLPAPERS[$current_index]} (index: $current_index)"
            echo "PCManFM desktop disabled: $([ -f "$PCMANFM_DISABLED_FLAG" ] && echo "Yes" || echo "No")"
        else
            echo "Wallpaper slideshow is not running (stale lock file)"
        fi
    else
        echo "Wallpaper slideshow is not running"
    fi
}

# Function to manually change to next wallpaper
next_wallpaper() {
    disable_pcmanfm_desktop
    change_wallpaper
}

# Function to restore current wallpaper (useful after JWM restart)
restore_current() {
    disable_pcmanfm_desktop
    restore_wallpaper
    echo "Restored current wallpaper"
}

# Function to show usage
usage() {
    echo "JWM Wallpaper Slideshow for Sparky Linux Bonsai DebianDog"
    echo "Usage: $0 {start|stop|status|next|restore|install|uninstall}"
    echo ""
    echo "Commands:"
    echo "  start     - Start the wallpaper slideshow daemon"
    echo "  stop      - Stop the wallpaper slideshow daemon"
    echo "  status    - Show current slideshow status"
    echo "  next      - Manually change to next wallpaper"
    echo "  restore   - Restore current wallpaper (useful after JWM restart)"
    echo "  install   - Install script to autostart with JWM"
    echo "  uninstall - Remove autostart and restore PCManFM desktop"
    echo ""
    echo "Note: This script disables PCManFM desktop mode to work properly"
}

# Main script logic
case "$1" in
    start)
        start_slideshow
        ;;
    stop)
        stop_slideshow
        ;;
    status)
        status_slideshow
        ;;
    next)
        next_wallpaper
        ;;
    restore)
        restore_current
        ;;
    install)
        echo "Creating JWM startup integration..."
        
        # Create the startup script
        cat > ~/.startup << 'STARTUP_EOF'
#!/bin/bash
# JWM Startup Script

# Log startup
echo "$(date) - JWM startup beginning" >> /tmp/jwm_startup.log

# Wait for X server to be fully ready
sleep 3

# Kill PCManFM desktop mode if running
killall pcmanfm 2>/dev/null
echo "$(date) - Killed PCManFM" >> /tmp/jwm_startup.log

# Clean up any stale wallpaper slideshow processes and lock files
pkill -f "wallpaper-slideshow start" 2>/dev/null
rm -f /tmp/wallpaper_slideshow.lock 2>/dev/null
echo "$(date) - Cleaned up old slideshow processes" >> /tmp/jwm_startup.log

# Wait for cleanup
sleep 2

# Set initial wallpaper directly with feh
feh --bg-fill /home/x/Wallpapers/BONSAI-WALLPAPERS/bonsai1-FUZZ.png
echo "$(date) - Set initial wallpaper" >> /tmp/jwm_startup.log

# Start fresh wallpaper slideshow daemon
/usr/local/bin/wallpaper-slideshow start &
echo "$(date) - Started slideshow daemon" >> /tmp/jwm_startup.log

STARTUP_EOF
        
        chmod +x ~/.startup
        echo "Wallpaper slideshow installed to JWM autostart"
        echo "Restart your system or run 'jwm -restart' to activate"
        ;;
    uninstall)
        echo "Removing wallpaper slideshow from autostart..."
        stop_slideshow
        rm -f ~/.startup
        enable_pcmanfm_desktop
        echo "Wallpaper slideshow uninstalled"
        ;;
    *)
        usage
        exit 1
        ;;
esac
SCRIPT_EOF

    # Make script executable
    sudo chmod +x "$SCRIPT_PATH"
    
    print_success "Wallpaper slideshow script installed at $SCRIPT_PATH"
}

# Function to setup JWM restart aliases system-wide
setup_jwm_aliases() {
    print_status "Setting up system-wide JWM restart aliases..."
    
    # Create backup of system bashrc
    sudo cp /etc/bash.bashrc /etc/bash.bashrc.backup.$(date +%Y%m%d_%H%M%S)
    
    # Check if our function already exists
    if ! grep -q "JWM restart with wallpaper slideshow support" /etc/bash.bashrc; then
        print_status "Adding JWM restart function to system bashrc..."
        
        sudo tee -a /etc/bash.bashrc > /dev/null << 'BASHRC_EOF'

# ============================================================================
# JWM Wallpaper Slideshow Integration
# Added by JWM Wallpaper Slideshow Installer
# ============================================================================

# JWM restart with wallpaper slideshow support
jwm() {
    if [[ "$1" == "-restart" ]]; then
        echo "🔄 Restarting JWM with wallpaper slideshow support..."
        
        # Stop wallpaper slideshow gracefully
        if command -v wallpaper-slideshow >/dev/null 2>&1; then
            wallpaper-slideshow stop 2>/dev/null
            echo "📱 Stopped wallpaper slideshow"
        fi
        
        # Small delay for cleanup
        sleep 1
        
        # Restart JWM
        echo "🚀 Restarting JWM..."
        command jwm -restart
        
    elif [[ "$1" == "-reload" ]]; then
        echo "🔄 Reloading JWM configuration..."
        command jwm -reload
        
        # Restart wallpaper slideshow after config reload
        if command -v wallpaper-slideshow >/dev/null 2>&1; then
            echo "📱 Restarting wallpaper slideshow..."
            wallpaper-slideshow stop 2>/dev/null
            sleep 1
            wallpaper-slideshow start &
        fi
        
    else
        # Pass through all other jwm commands normally
        command jwm "$@"
    fi
}

# Additional helpful aliases for wallpaper management
alias wp-next='wallpaper-slideshow next'
alias wp-status='wallpaper-slideshow status'
alias wp-start='wallpaper-slideshow start'
alias wp-stop='wallpaper-slideshow stop'
alias wp-install='wallpaper-slideshow install'

# Quick wallpaper commands
alias bonsai1='feh --bg-fill /home/x/Wallpapers/BONSAI-WALLPAPERS/bonsai1-FUZZ.png'
alias bonsai2='feh --bg-fill /home/x/Wallpapers/BONSAI-WALLPAPERS/bonsai2-FUZZ.png'
alias bonsai3='feh --bg-fill /home/x/Wallpapers/BONSAI-WALLPAPERS/bonsai3-FUZZ.png'
alias bonsai4='feh --bg-fill /home/x/Wallpapers/BONSAI-WALLPAPERS/bonsai4-FUZZ.png'
alias bonsai5='feh --bg-fill /home/x/Wallpapers/BONSAI-WALLPAPERS/bonsai5-FUZZ.png'

BASHRC_EOF

        print_success "JWM restart function and aliases added to system bashrc"
    else
        print_warning "JWM restart function already exists in system bashrc"
    fi
    
    # Also add to user's bashrc if it exists
    if [[ -f ~/.bashrc ]]; then
        print_status "Adding aliases to user bashrc..."
        
        if ! grep -q "JWM Wallpaper Slideshow Integration" ~/.bashrc; then
            tee -a ~/.bashrc > /dev/null << 'USER_BASHRC_EOF'

# ============================================================================
# JWM Wallpaper Slideshow Integration (User)
# Added by JWM Wallpaper Slideshow Installer
# ============================================================================

# Quick wallpaper shortcuts
alias wp='wallpaper-slideshow'
alias next-wallpaper='wallpaper-slideshow next'
alias wallpaper-status='wallpaper-slideshow status'

USER_BASHRC_EOF
            print_success "User aliases added to ~/.bashrc"
        fi
    fi
}

# Function to install JWM autostart
install_jwm_autostart() {
    print_status "Installing JWM autostart configuration..."
    
    # Install using the wallpaper script's install function
    "$SCRIPT_PATH" install
    
    print_success "JWM autostart configuration installed"
}

# Function to test installation
test_installation() {
    print_status "Testing wallpaper slideshow installation..."
    
    # Test script existence and permissions
    if [[ -x "$SCRIPT_PATH" ]]; then
        print_success "Wallpaper script is executable"
    else
        print_error "Wallpaper script is not executable"
        return 1
    fi
    
    # Test wallpaper files
    local missing_files=0
    for wallpaper in "${WALLPAPERS[@]}"; do
        if [[ ! -f "$WALLPAPER_DIR/$wallpaper" ]]; then
            print_error "Missing wallpaper: $wallpaper"
            ((missing_files++))
        fi
    done
    
    if [[ $missing_files -eq 0 ]]; then
        print_success "All wallpaper files present"
    else
        print_error "$missing_files wallpaper files missing"
        return 1
    fi
    
    # Test feh
    if command -v feh >/dev/null 2>&1; then
        print_success "feh is available"
    else
        print_error "feh is not available"
        return 1
    fi
    
    # Test manual wallpaper change
    print_status "Testing manual wallpaper change..."
    if "$SCRIPT_PATH" next; then
        print_success "Manual wallpaper change works"
    else
        print_warning "Manual wallpaper change had issues (check if X11 is running)"
    fi
    
    print_success "Installation test completed successfully"
}

# Function to display final instructions
show_final_instructions() {
    echo
    print_header
    print_success "JWM Wallpaper Slideshow installation completed!"
    echo
    echo -e "${BLUE}📁 Wallpapers location:${NC} $WALLPAPER_DIR"
    echo -e "${BLUE}🛠️  Script location:${NC} $SCRIPT_PATH"
    echo -e "${BLUE}📜 Startup script:${NC} ~/.startup"
    echo
    echo -e "${YELLOW}Available Commands:${NC}"
    echo "  wallpaper-slideshow start    - Start slideshow"
    echo "  wallpaper-slideshow stop     - Stop slideshow"
    echo "  wallpaper-slideshow status   - Check status"
    echo "  wallpaper-slideshow next     - Next wallpaper"
    echo "  jwm -restart                 - Restart JWM (with slideshow support)"
    echo
    echo -e "${YELLOW}Quick Aliases:${NC}"
    echo "  wp-next      - Next wallpaper"
    echo "  wp-status    - Check status"
    echo "  wp-start     - Start slideshow"
    echo "  wp-stop      - Stop slideshow"
    echo "  bonsai1-5    - Set specific wallpaper"
    echo
    echo -e "${GREEN}🎉 To activate everything:${NC}"
    echo "  1. Restart your terminal: ${BLUE}source /etc/bash.bashrc${NC}"
    echo "  2. Test: ${BLUE}wallpaper-slideshow next${NC}"
    echo "  3. Restart JWM: ${BLUE}jwm -restart${NC}"
    echo
    echo -e "${YELLOW}⚙️  The slideshow will:${NC}"
    echo "  • Change wallpapers every 10 minutes"
    echo "  • Start automatically on boot"
    echo "  • Handle JWM restarts properly"
    echo "  • Disable PCManFM desktop mode automatically"
    echo
    print_success "Enjoy your dynamic bonsai wallpapers! 🌳"
}

# Main installation function
main() {
    print_header
    
    print_status "Starting JWM Wallpaper Slideshow installation..."
    echo
    
    # Check if running as root
    check_root
    
    # Installation steps
    check_dependencies
    echo
    
    create_wallpaper_directory
    echo
    
    download_wallpapers
    echo
    
    install_slideshow_script
    echo
    
    setup_jwm_aliases
    echo
    
    install_jwm_autostart
    echo
    
    test_installation
    echo
    
    show_final_instructions
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "JWM Wallpaper Slideshow Master Installer"
        echo "Usage: $0 [--help|-h|--uninstall]"
        echo
        echo "Options:"
        echo "  --help, -h        Show this help message"
        echo "  --uninstall       Uninstall wallpaper slideshow"
        exit 0
        ;;
    --uninstall)
        print_status "Uninstalling JWM Wallpaper Slideshow..."
        
        # Stop slideshow
        if [[ -x "$SCRIPT_PATH" ]]; then
            "$SCRIPT_PATH" stop 2>/dev/null || true
            "$SCRIPT_PATH" uninstall 2>/dev/null || true
        fi
        
        # Remove script
        sudo rm -f "$SCRIPT_PATH"
        
        # Remove wallpapers (ask for confirmation)
        read -p "Remove wallpaper files from $WALLPAPER_DIR? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$WALLPAPER_DIR"
            print_success "Wallpaper files removed"
        fi
        
        # Restore bashrc (ask for confirmation)
        if [[ -f /etc/bash.bashrc.backup.* ]]; then
            read -p "Restore original system bashrc? [y/N]: " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                latest_backup=$(ls -t /etc/bash.bashrc.backup.* | head -1)
                sudo cp "$latest_backup" /etc/bash.bashrc
                print_success "System bashrc restored"
            fi
        fi
        
        print_success "JWM Wallpaper Slideshow uninstalled"
        exit 0
        ;;
    "")
        # No arguments, run main installation
        main
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac