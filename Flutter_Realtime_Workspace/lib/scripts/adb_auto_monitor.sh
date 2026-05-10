#!/bin/bash

# macOS ADB Device Monitor
# Uses system_profiler to detect USB device changes

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Path to your main ADB wireless setup script
SCRIPT_DIR="$(dirname "$0")"
SCRIPT_PATH="$SCRIPT_DIR/adb_wireless_setup.sh"

# File to track previous USB devices
USB_STATE_FILE="/tmp/adb_usb_devices_state"

# Android vendor IDs to monitor
ANDROID_VENDOR_IDS=(
    "18d1"  # Google
    "04e8"  # Samsung
    "22b8"  # Motorola
    "0bb4"  # HTC
    "12d1"  # Huawei
    "19d2"  # ZTE
    "1004"  # LG
    "0502"  # Acer
    "0b05"  # Asus
    "413c"  # Dell
    "0489"  # Foxconn
    "04dd"  # Sharp
    "0fce"  # Sony Ericsson
    "166a"  # EmPIA Technology
    "1f53"  # OnePlus
    "2916"  # Android
    "2a45"  # Meizu
)

# Check if ADB is available
check_adb() {
    if ! command -v adb &> /dev/null; then
        # Try common installation paths
        local adb_paths=(
            "/usr/local/bin/adb"
            "/opt/homebrew/bin/adb"
            "$HOME/Library/Android/sdk/platform-tools/adb"
            "$HOME/Android/Sdk/platform-tools/adb"
        )
        
        for path in "${adb_paths[@]}"; do
            if [[ -f "$path" ]]; then
                export PATH="$(dirname "$path"):$PATH"
                log "Found ADB at: $path"
                return 0
            fi
        done
        
        error "ADB not found. Please install Android SDK Platform Tools"
        return 1
    fi
    return 0
}

# Get current USB devices with Android vendor IDs
get_android_usb_devices() {
    local devices=""
    for vendor_id in "${ANDROID_VENDOR_IDS[@]}"; do
        local found=$(system_profiler SPUSBDataType 2>/dev/null | grep -i "Vendor ID: 0x$vendor_id" -A 10 -B 2 | grep "Serial Number:" | awk '{print $3}' || true)
        if [[ -n "$found" ]]; then
            devices="$devices$found\n"
        fi
    done
    echo -e "$devices" | sort | uniq | grep -v "^$" || true
}

# Monitor for new Android devices
monitor_android_devices() {
    log "Starting macOS ADB device monitor..."
    log "Monitoring USB ports for Android devices..."
    
    # Initialize state file
    get_android_usb_devices > "$USB_STATE_FILE"
    
    while true; do
        sleep 3
        
        # Get current devices
        local current_devices=$(get_android_usb_devices)
        local previous_devices=""
        
        if [[ -f "$USB_STATE_FILE" ]]; then
            previous_devices=$(cat "$USB_STATE_FILE")
        fi
        
        # Check for new devices
        if [[ "$current_devices" != "$previous_devices" ]]; then
            # Find newly connected devices
            local new_devices=$(comm -13 <(echo "$previous_devices" | sort) <(echo "$current_devices" | sort))
            
            if [[ -n "$new_devices" ]]; then
                success "New Android device(s) detected via USB"
                
                # Wait for ADB to recognize the device
                sleep 2
                
                # Check if ADB can see the device
                local adb_devices=$(adb devices | grep -v "List of devices" | grep "device" | grep -v ":" | awk '{print $1}')
                
                if [[ -n "$adb_devices" ]]; then
                    success "ADB device ready, starting wireless setup..."
                    
                    # Run the wireless setup script
                    if [[ -f "$SCRIPT_PATH" ]]; then
                        bash "$SCRIPT_PATH" &
                    else
                        error "Main ADB script not found at: $SCRIPT_PATH"
                    fi
                else
                    warning "USB device detected but not ready for ADB. Check USB debugging is enabled."
                fi
            fi
            
            # Update state file
            echo "$current_devices" > "$USB_STATE_FILE"
        fi
    done
}

# Cleanup function
cleanup() {
    log "Cleaning up monitor..."
    [[ -f "$USB_STATE_FILE" ]] && rm -f "$USB_STATE_FILE"
    exit 0
}

# Handle script interruption
trap cleanup INT TERM

# Main execution
main() {
    log "macOS ADB Monitor starting..."
    
    if ! check_adb; then
        exit 1
    fi
    
    if [[ ! -f "$SCRIPT_PATH" ]]; then
        error "Main ADB script not found at: $SCRIPT_PATH"
        error "Please ensure adb_wireless_setup.sh is in the same directory"
        exit 1
    fi
    
    monitor_android_devices
}

main "$@"